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
        if !result {
            self.error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to save review"])
        }
        return result
    }

    func deleteReview(book: Book, review: Review) async -> Bool {
        let result = await firestoreService.deleteReview(for: book, review: review)
        if !result {
            self.error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to delete review"])
        }
        return result
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
            }
        }
    }

    func fetchReviewsByUser(userID: String) async {
        do {
            let fetchedReviews = try await firestoreService.fetchReviewsByUser(userID: userID)
            DispatchQueue.main.async {
                self.reviews = fetchedReviews
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error
            }
        }
    }
}
