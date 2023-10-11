//
//  ReviewViewModel.swift
//  Bookmarked
//
//  Created by Vivien on 9/18/23.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class ReviewViewModel: ObservableObject {
    @Published var review = Review()
    
    func saveReview(book: Book, review: Review) async -> Bool {
        let db = Firestore.firestore()
        
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
    
    func deleteReview(book: Book, review: Review) async -> Bool {
        let db = Firestore.firestore()
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
}
