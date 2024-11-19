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
    var reviews: [String: [Review]] = [:]
    var favorites: [String: Bool] = [:]
    var userReviews: [String: [ReviewReference]] = [:]

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
        await updateUserReviews(userId: review.userId ?? "", bookID: firestoreId, reviewID: review.id ?? "", remove: false)
        return true
    }
    
    func fetchReviewID(for book: Book, review: Review) async -> String? {
        guard let firestoreId = book.firestoreId else { return nil }
        if let reviewIndex = reviews[firestoreId]?.firstIndex(where: { $0.userId == review.userId && $0.postedOn == review.postedOn }) {
            return reviews[firestoreId]?[reviewIndex].id
        }
        return nil
    }

    func deleteReview(for book: Book, review: Review) async -> Bool {
        guard let firestoreId = book.firestoreId, let index = reviews[firestoreId]?.firstIndex(where: { $0.id == review.id }) else {
            return false
        }
        reviews[firestoreId]?.remove(at: index)
        await updateUserReviews(userId: review.userId ?? "", bookID: firestoreId, reviewID: review.id ?? "", remove: true)
        return true
    }

    func fetchBook(byID bookID: String) async throws -> Book? {
        guard let book = books[bookID] else {
            throw MockError.notFound
        }
        return book
    }

    func fetchReviews(forBookWithFirestoreId firestoreId: String) async throws -> [Review] {
        return reviews[firestoreId] ?? []
    }

    func fetchReviewsForUser(userId: String) async throws -> [Review] {
        var allReviews: [Review] = []
        guard let reviewReferences = userReviews[userId] else {
            return allReviews
        }
        
        for reference in reviewReferences {
            if let bookReviews = reviews[reference.bookID] {
                if let review = bookReviews.first(where: { $0.id == reference.reviewID }) {
                    allReviews.append(review)
                }
            }
        }
        return allReviews
    }

    func fetchBooksForReviews(reviews: [Review]) async throws -> [String: Book] {
        var booksDict: [String: Book] = [:]
        for review in reviews {
            if let bookID = review.bookID {
                if let book = books[bookID] {
                    booksDict[bookID] = book
                }
            }
        }
        return booksDict
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

    func updateUserReviews(userId: String, bookID: String, reviewID: String, remove: Bool = false) async {
        var userReviewReferences = userReviews[userId, default: []]
        
        if remove {
            userReviewReferences.removeAll { $0.bookID == bookID && $0.reviewID == reviewID }
        } else {
            userReviewReferences.append(ReviewReference(bookID: bookID, reviewID: reviewID))
        }
        
        userReviews[userId] = userReviewReferences
    }

    enum MockError: Error {
        case notFound
    }
}




