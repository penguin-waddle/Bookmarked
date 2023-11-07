//
//  FirestoreService.swift
//  BookmarkedTests
//
//  Created by Vivien on 11/1/23.
//

import FirebaseFirestore
import FirebaseAuth

protocol FirestoreServiceProtocol {
    func saveBook(_ book: Book) async -> Bool
    func bookExists(isbn10: String?, isbn13: String?) async -> Bool
    func saveBookIfNotExists(book: Book) async -> Bool
    func saveReview(for book: Book, review: Review) async -> Bool
    func deleteReview(for book: Book, review: Review) async -> Bool
    func getBookId(book: Book, fromAPI: Bool) -> String
    func checkIfBookIsFavorite(userId: String, book: Book, fromAPI: Bool, completion: @escaping (Bool, String?, Error?) -> Void)
    func toggleFavoriteStatus(isFavorite: Bool, userId: String, book: Book, fromAPI: Bool, completion: @escaping (Bool, Error?) -> Void)
}

class FirestoreService: FirestoreServiceProtocol, ObservableObject {
    
    private let db = Firestore.firestore()
    
    func saveBook(_ book: Book) async -> Bool {
        if let id = book.id { // book already exists, so save
            do {
                try await db.collection("books").document(id).setData(book.dictionary)
                return true
            } catch {
                print("Error: \(error.localizedDescription)")
                return false
            }
        } else {
            do {
                try await db.collection("books").addDocument(data: book.dictionary)
                return true
            } catch {
                print("Error: \(error.localizedDescription)")
                return false
            }
        }
    }

    func bookExists(isbn10: String?, isbn13: String?) async -> Bool {
        var query: Query!
        
        if let isbn10Value = isbn10 {
            query = db.collection("books").whereField("isbn10", isEqualTo: isbn10Value)
        } else if let isbn13Value = isbn13 {
            query = db.collection("books").whereField("isbn13", isEqualTo: isbn13Value)
        } else {
            // Neither isbn10 nor isbn13 provided, so return false
            return false
        }

        let snapshot = try? await query.getDocuments()
        return snapshot?.documents.count ?? 0 > 0
    }

    func saveBookIfNotExists(book: Book) async -> Bool {
        let exists = await bookExists(isbn10: book.isbn10, isbn13: book.isbn13)
        if !exists {
            return await saveBook(book)
        }
        return true
    }
    
    func saveReview(for book: Book, review: Review) async -> Bool {
            guard let bookID = book.id else {
                print("Error: book.id = nil")
                return false
            }
            
            var updatedReview = review
            updatedReview.bookID = bookID  // Setting the bookID of the review
            updatedReview.userID = Auth.auth().currentUser?.uid  // Setting the userID of the review
            
            let collectionString = "books/\(bookID)/reviews"
            
            if let id = updatedReview.id { // review already exists, so save
                do {
                    try await db.collection(collectionString).document(id).setData(updatedReview.dictionary)
                    print("Data updated successfully!")
                    return true
                } catch {
                    print("Error: Could not update data in 'reviews' \(error.localizedDescription)")
                    return false
                }
            } else { // no id? new review to add
                do {
                    try await db.collection(collectionString).addDocument(data: updatedReview.dictionary)
                    print("Data added successfully!")
                    return true
                } catch {
                    print("Error: Could not create a new review in 'reviews' \(error.localizedDescription)")
                    return false
                }
            }
        }
        
        func deleteReview(for book: Book, review: Review) async -> Bool {
            guard let bookID = book.id, let reviewID = review.id else {
                print("Error: book.id = \(book.id ?? "nil"), review.id = \(review.id ?? "nil"). This should not have happened.")
                return false
            }
            
            do {
                let _ = try await db.collection("books").document(bookID).collection("reviews").document(reviewID).delete()
                print("Document successfully deleted.")
                return true
            } catch {
                print("Error: Removing document \(error.localizedDescription)")
                return false
            }
        }
    
    func getBookId(book: Book, fromAPI: Bool) -> String {
           if fromAPI {
               return book.id ?? ""
           } else {
               if let range = book.id?.range(of: "_") {
                   return String(book.id?[range.upperBound...] ?? "")
               } else {
                   return ""
               }
           }
       }
    
    func checkIfBookIsFavorite(userId: String, book: Book, fromAPI: Bool, completion: @escaping (Bool, String?, Error?) -> Void) {
         let bookId = getBookId(book: book, fromAPI: fromAPI)
         let documentId = "\(userId)_\(bookId)"
         let favoriteDocument = db.collection("favorites").document(documentId)

         favoriteDocument.getDocument { (documentSnapshot, error) in
             if let error = error {
                 completion(false, nil, error)
             } else if let document = documentSnapshot, document.exists {
                 completion(true, documentId, nil)
             } else {
                 completion(false, nil, nil)
             }
         }
     }

    func toggleFavoriteStatus(isFavorite: Bool, userId: String, book: Book, fromAPI: Bool, completion: @escaping (Bool, Error?) -> Void) {
         let bookId = getBookId(book: book, fromAPI: fromAPI)
         let documentId = "\(userId)_\(bookId)"
         let favoriteDocument = db.collection("favorites").document(documentId)

         if isFavorite {
             favoriteDocument.delete() { error in
                 completion(error == nil, error)
             }
         } else {
             let favoriteData: [String: Any] = [
                 "userID": userId,
                 "bookID": book.id ?? "",
                 "title": book.title,
                 "author": book.author,
                 "imageUrl": book.imageUrl ?? "",
                 "description": book.description ?? "",
                 "publishedDate": book.publishedDate ?? "",
                 "publisher": book.publisher ?? ""
             ]
             favoriteDocument.setData(favoriteData) { error in
                 completion(error == nil, error)
             }
         }
     }
 }
