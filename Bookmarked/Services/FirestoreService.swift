//
//  FirestoreService.swift
//  BookmarkedTests
//
//  Created by Vivien on 11/1/23.
//

import FirebaseFirestore
import FirebaseAuth
import Combine

protocol FirestoreServiceProtocol {
    func saveBook(_ book: Book) async throws -> String
    func bookExists(isbn10: String?, isbn13: String?) async -> String?
    func saveBookIfNotExists(book: Book) async -> String?
    func saveReview(for book: Book, review: Review) async -> Bool
    func deleteReview(for book: Book, review: Review) async -> Bool
    func fetchBook(byID bookID: String) async throws -> Book?
    func fetchReviews(forBookWithFirestoreId firestoreId: String) async throws -> [Review]
    func fetchReviewsByUser(userId: String) async throws -> [Review]
    func getBookId(book: Book, fromAPI: Bool) -> String
    func fetchFavorites(userId: String) async throws -> [Book]
    func checkIfBookIsFavorite(userId: String, firestoreId: String) -> AnyPublisher<Bool, Error>
    func toggleFavoriteStatus(userId: String, firestoreId: String, book: Book, isFavorite: Bool) -> AnyPublisher<Bool, Error>
}

class FirestoreService: FirestoreServiceProtocol, ObservableObject {
    
    static let shared = FirestoreService()
    private init() {}
    
    private let db = Firestore.firestore()
    
    func saveBook(_ book: Book) async throws -> String {
        var ref: DocumentReference?
        if let firestoreId = book.firestoreId, !firestoreId.isEmpty {
            ref = db.collection("books").document(firestoreId)
            try await ref!.setData(book.dictionary)
        } else {
            ref = try await db.collection("books").addDocument(data: book.dictionary)
        }
        return ref!.documentID // Return the Firestore ID of the saved or updated book
    }
    
    func bookExists(isbn10: String?, isbn13: String?) async -> String? {
        var query: Query!

        if let isbn10Value = isbn10 {
            query = db.collection("books").whereField("isbn10", isEqualTo: isbn10Value)
        } else if let isbn13Value = isbn13 {
            query = db.collection("books").whereField("isbn13", isEqualTo: isbn13Value)
        } else {
            // If neither ISBN is provided, return nil indicating no book found
            return nil
        }

        let snapshot = try? await query.getDocuments()
        if let document = snapshot?.documents.first {
            // Assuming each book has a unique ISBN, returning the first match's document ID
            return document.documentID
        } else {
            // No book found with the given ISBN
            return nil
        }
    }
    
    func saveBookIfNotExists(book: Book) async -> String? {
        // Attempt to fetch the Firestore ID by ISBN
        let firestoreId = await bookExists(isbn10: book.isbn10, isbn13: book.isbn13)
        
        if let firestoreId = firestoreId {
            // Book exists, return the existing Firestore ID
            return firestoreId
        } else {
            // Book doesn't exist, attempt to save it
            do {
                let newFirestoreId = try await saveBook(book)
                return newFirestoreId
            } catch {
                print("Error saving book: \(error)")
                return nil
            }
        }
    }
    
    func saveReview(for book: Book, review: Review) async -> Bool {
        guard let firestoreId = book.firestoreId else {
            print("Error: book.firestoreId is nil")
            return false
        }
        
        var updatedReview = review
        updatedReview.bookID = firestoreId  // Use Firestore ID of the book
        updatedReview.userId = Auth.auth().currentUser?.uid  // Setting the userId of the review
        
        let collectionPath = "books/\(firestoreId)/reviews"
        
        do {
            if let reviewId = updatedReview.id {
                // If review has an ID, it exists and should be updated
                try await db.collection(collectionPath).document(reviewId).setData(updatedReview.dictionary)
            } else {
                // New review, add it to the collection
                _ = try await db.collection(collectionPath).addDocument(data: updatedReview.dictionary)
            }
            print("Review saved successfully")
            return true
        } catch {
            print("Error saving review: \(error)")
            return false
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
    
    func fetchBook(byID bookID: String) async throws -> Book? {
        print("FirestoreService: Fetching book with ID \(bookID)")
        do {
            let docRef = db.collection("books").document(bookID)
            let snapshot = try await docRef.getDocument()
            let book = try snapshot.data(as: Book.self)
            return book
        } catch {
            print("Error fetching book: \(error.localizedDescription)")
            throw error
        }
    }
    
    func fetchReviews(forBookWithFirestoreId firestoreId: String) async throws -> [Review] {
        do {
            let reviewsRef = db.collection("books").document(firestoreId).collection("reviews")
            let snapshot = try await reviewsRef.getDocuments()
            let reviews = snapshot.documents.compactMap { document in
                try? document.data(as: Review.self)
            }
            return reviews
        } catch {
            print("Error fetching reviews: \(error.localizedDescription)")
            throw error
        }
    }
    
    func fetchReviewsByUser(userId: String) async throws -> [Review] {
        let reviewsRef = db.collectionGroup("reviews").whereField("userId", isEqualTo: userId)
        let snapshot = try await reviewsRef.getDocuments()
        return snapshot.documents.compactMap { document -> Review? in
            try? document.data(as: Review.self)
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
    
    func fetchFavorites(userId: String) async throws -> [Book] {
        let favoritesRef = db.collection("favorites").whereField("userId", isEqualTo: userId)
        let snapshot = try await favoritesRef.getDocuments()
        return snapshot.documents.compactMap { document -> Book? in
            try? document.data(as: Book.self)
        }
    }
    
    func checkIfBookIsFavorite(userId: String, firestoreId: String) -> AnyPublisher<Bool, Error> {
        let docRef = db.collection("favorites").document("\(userId)_\(firestoreId)")
        return Future<Bool, Error> { promise in
            docRef.getDocument { snapshot, error in
                if let error = error {
                    print("Error checking favorite status: \(error.localizedDescription)")
                    promise(.failure(error))
                } else {
                    let exists = snapshot?.exists ?? false
                    promise(.success(exists))
                }
            }
        }
        .eraseToAnyPublisher()
    }


    func toggleFavoriteStatus(userId: String, firestoreId: String, book: Book, isFavorite: Bool) -> AnyPublisher<Bool, Error> {
        let docRef = Firestore.firestore().collection("favorites").document("\(userId)_\(firestoreId)")
        
        return Future<Bool, Error> { promise in
            if isFavorite {
                print("Deleting favorite document:", docRef.path)  // Debugging
                docRef.delete { error in
                    if let error = error {
                        print("Failed to delete favorite:", error.localizedDescription)  // Log error
                        promise(.failure(error))
                    } else {
                        promise(.success(false))  // Successfully deleted, no longer a favorite
                    }
                }
            } else {
                print("Adding favorite document:", docRef.path)  // Debugging
                let favoriteData: [String: Any] = [
                                "userId": userId,
                                "bookID": firestoreId, 
                                "title": book.title,
                                "author": book.author,
                                "imageUrl": book.imageUrl ?? "",
                                "description": book.description ?? "",
                                "publishedDate": book.publishedDate ?? "",
                                "publisher": book.publisher ?? "",
                                "pageCount": book.pageCount ?? "",
                                "categories": book.categories ?? [],
                            ]
                docRef.setData(favoriteData) { error in
                    if let error = error {
                        print("Failed to add favorite:", error.localizedDescription)  // Log error
                        promise(.failure(error))
                    } else {
                        promise(.success(true))  // Successfully added, now a favorite
                    }
                }
            }
        }.eraseToAnyPublisher()
    }

}
