//
//  MockFirestoreService.swift
//  BookmarkedTests
//
//  Created by Vivien on 11/1/23.
//

import Foundation
import Combine

class MockFirestoreService: FirestoreServiceProtocol {
    var books: [String: Book] = [:]
    var reviews: [String: [Review]] = [:]  // Mapping Firestore ID to reviews
    var favorites: [String: Bool] = [:]  // Maps Firestore ID to favorite status

    func saveBook(_ book: Book) async throws -> String {
        let firestoreId = book.firestoreId ?? UUID().uuidString
        books[firestoreId] = book
        return firestoreId
    }

    func bookExists(isbn10: String?, isbn13: String?) async -> String? {
        for (firestoreId, book) in books {
            if book.isbn10 == isbn10 || book.isbn13 == isbn13 {
                return firestoreId
            }
        }
        return nil
    }

    func saveBookIfNotExists(book: Book) async -> String? {
        if let firestoreId = await bookExists(isbn10: book.isbn10, isbn13: book.isbn13) {
            return firestoreId
        } else {
            let newFirestoreId = UUID().uuidString
            books[newFirestoreId] = book
            return newFirestoreId
        }
    }

    func saveReview(for book: Book, review: Review) async -> Bool {
        guard let firestoreId = book.firestoreId else { return false }
        var bookReviews = reviews[firestoreId, default: []]
        bookReviews.append(review)
        reviews[firestoreId] = bookReviews
        return true
    }

    func deleteReview(for book: Book, review: Review) async -> Bool {
        guard let firestoreId = book.firestoreId, let index = reviews[firestoreId]?.firstIndex(where: { $0.id == review.id }) else {
            return false
        }
        reviews[firestoreId]?.remove(at: index)
        return true
    }

    func fetchBook(byID bookID: String) async throws -> Book? {
        guard let book = books[bookID] else {
            throw MockError.notFound
        }
        return book
    }
     
    func getBookId(book: Book, fromAPI: Bool) -> String {
        return book.firestoreId ?? UUID().uuidString
    }

    func fetchReviews(forBookWithFirestoreId firestoreId: String) async throws -> [Review] {
        return reviews[firestoreId] ?? []
    }

    func fetchReviewsByUser(userId: String) async throws -> [Review] {
        let allReviews = reviews.values.flatMap { $0 }
        return allReviews.filter { $0.userId == userId }
    }

    func fetchFavorites(userId: String) async throws -> [Book] {
        let favoriteBookIds = favorites.compactMap { $0.value ? $0.key : nil }
        return favoriteBookIds.compactMap { books[$0] }
    }

    func checkIfBookIsFavorite(userId: String, firestoreId: String) -> AnyPublisher<Bool, Error> {
        let isFavorite = favorites["\(userId)_\(firestoreId)"] ?? false
        return Just(isFavorite).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func toggleFavoriteStatus(userId: String, firestoreId: String, book: Book, isFavorite: Bool) -> AnyPublisher<Bool, Error> {
        favorites["\(userId)_\(firestoreId)"] = !isFavorite
        return Just(!isFavorite).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    enum MockError: Error {
        case notFound
    }
}
