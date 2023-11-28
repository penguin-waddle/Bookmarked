//
//  MockFirestoreService.swift
//  BookmarkedTests
//
//  Created by Vivien on 11/1/23.
//

import Foundation

class MockFirestoreService: FirestoreServiceProtocol {

    // Mocking a simple in-memory store for tests
    var books: [String: Book] = [:]
    var reviews: [String: Review] = [:]
    var favoriteBooks: [String: Bool] = [:]

    func saveBook(_ book: Book) async -> Bool {
        // Implement mock logic to save the book
        // For simplicity, we're using the book's id as the key
        if let id = book.id {
            books[id] = book
            return true
        }
        return false
    }

    func bookExists(isbn10: String?, isbn13: String?) async -> Bool {
        // Implement mock logic to check if the book exists
        if let isbn10Value = isbn10 {
            return books.values.contains { $0.isbn10 == isbn10Value }
        } else if let isbn13Value = isbn13 {
            return books.values.contains { $0.isbn13 == isbn13Value }
        }
        return false
    }

    func saveBookIfNotExists(book: Book) async -> Bool {
        if !(await bookExists(isbn10: book.isbn10, isbn13: book.isbn13)) {
            return await saveBook(book)
        }
        return true
    }

    func saveReview(for book: Book, review: Review) async -> Bool {
        if let id = review.id {
            reviews[id] = review
            return true
        }
        return false
    }

    func deleteReview(for book: Book, review: Review) async -> Bool {
        if let id = review.id {
            reviews.removeValue(forKey: id)
            return true
        }
        return false
    }
    
    func getBookId(book: Book, fromAPI: Bool) -> String {
            // Mock implementation: simply return a fixed string or a mock id based on the 'fromAPI' flag
            if fromAPI {
                return "mocked_api_id_for_\(book.title.replacingOccurrences(of: " ", with: "_"))"
            } else {
                // Mock a local database id format
                return "local_db_id_\(book.title.replacingOccurrences(of: " ", with: "_"))"
            }
        }

    func checkIfBookIsFavorite(userId: String, book: Book, fromAPI: Bool, completion: @escaping (Bool, String?, Error?) -> Void) {
        let bookId = getBookId(book: book, fromAPI: fromAPI)
        let documentId = "\(userId)_\(bookId)"
        let isFavorite = favoriteBooks[documentId] ?? false
        completion(isFavorite, documentId, nil)
    }

    func toggleFavoriteStatus(isFavorite: Bool, userId: String, book: Book, fromAPI: Bool, completion: @escaping (Bool, Error?) -> Void) {
        let bookId = getBookId(book: book, fromAPI: fromAPI)
        let documentId = "\(userId)_\(bookId)"
        
        if isFavorite {
            // Remove from favorites
            favoriteBooks.removeValue(forKey: documentId)
            completion(true, nil)
        } else {
            // Add to favorites
            favoriteBooks[documentId] = true
            completion(true, nil)
        }
    }

       // simple MockError enum to simulate different kinds of errors
       enum MockError: Error {
           case notFound
       }

}
