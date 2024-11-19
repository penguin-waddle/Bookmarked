//
//  ReviewViewModel.swift
//  Bookmarked
//
//  Created by Vivien on 9/18/23.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class ReviewViewModel: ObservableObject {
    private var firestoreService: FirestoreServiceProtocol

    @Published var review = Review()
    @Published var reviews: [Review] = []
    @Published var reviewBooks: [String: Book] = [:]
    @Published var error: Error?

    init(firestoreService: FirestoreServiceProtocol = FirestoreService.shared) {
        self.firestoreService = firestoreService
    }

    func saveReview(book: Book, review: Review) async -> Bool {
        let result = await firestoreService.saveReview(for: book, review: review)
        if result {
            if let index = self.reviews.firstIndex(where: { $0.id == review.id }) {
                self.reviews[index] = review
            } else {
                self.reviews.append(review)
            }
        } else {
            self.error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to save review"])
        }
        return result
    }

    func deleteReview(book: Book, review: Review) async -> Bool {
        guard let bookID = book.firestoreId, let reviewID = review.id else {
            print("Error: BookID or ReviewID is nil")
            return false
        }

        print("Attempting to delete review with ID: \(reviewID) for book ID: \(bookID)")
        let reviewDeleted = await firestoreService.deleteReview(for: book, review: review)
        if !reviewDeleted {
            print("Failed to delete review from Firestore.")
            return false
        }
        print("Successfully deleted review with ID: \(reviewID)")

        // Remove the review reference from the user's reviews array
        print("Removing review reference from user \(Auth.auth().currentUser?.uid ?? "nil")")
        await firestoreService.updateUserReviews(
            userId: Auth.auth().currentUser?.uid ?? "",
            bookID: bookID,
            reviewID: reviewID,
            remove: true  // Indicate removal
        )

        return true
    }

    func fetchBookForReview(firestoreId: String) async {
        do {
            if let book = try await firestoreService.fetchBook(byID: firestoreId) {
                DispatchQueue.main.async {
                    self.reviewBooks[firestoreId] = book
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error
            }
        }
    }

    func fetchReviews(for firestoreId: String) async {
        do {
            let fetchedReviews = try await firestoreService.fetchReviews(forBookWithFirestoreId: firestoreId)
            DispatchQueue.main.async {
                self.reviews = fetchedReviews
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error
                print("Error fetching reviews: \(error)")
            }
        }
    }

    func fetchReviewsForUser(userId: String) async {
        do {
            let fetchedReviews = try await firestoreService.fetchReviewsForUser(userId: userId)
            print("Fetched reviews: \(fetchedReviews)")
            let fetchedBooks = try await firestoreService.fetchBooksForReviews(reviews: fetchedReviews)
            print("Fetched books for reviews: \(fetchedBooks)")
            DispatchQueue.main.async {
                self.reviews = fetchedReviews
                self.reviewBooks = fetchedBooks
                print("Reviews in fetchReviewsForUser: \(self.reviews)")
                print("ReviewBooks in fetchReviewsForUser: \(self.reviewBooks)")
            }
        } catch {
            print("Error fetching reviews for user: \(error)")
        }
    }

    func resetData() {
        DispatchQueue.main.async {
            self.reviews = []
            self.error = nil
        }
    }
}

