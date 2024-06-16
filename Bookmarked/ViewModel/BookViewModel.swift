//
//  BookViewModel.swift
//  Bookmarked
//
//  Created by Vivien on 8/23/23.
//

import Foundation
import FirebaseFirestore

@MainActor
class BookViewModel: ObservableObject {
    private var firestoreService: FirestoreServiceProtocol
    
    init(firestoreService: FirestoreServiceProtocol = FirestoreService.shared) {
        self.firestoreService = firestoreService
    }
    
    @Published var book = Book()
    @Published var isFromAPI: Bool = false
    @Published var fetchError: Error?
    @Published var dataFetched = false // Tracks if data has been fetched already
    
    func saveBook(book: Book) async -> Bool {
        do {
            let firestoreId = try await firestoreService.saveBook(book)
            self.book.firestoreId = firestoreId
            return true
        } catch {
            print("Error saving book: \(error)")
            return false
        }
    }
    
    func bookExists(isbn10: String?, isbn13: String?) async -> Bool {
        return ((await firestoreService.bookExists(isbn10: isbn10, isbn13: isbn13)) != nil)
    }
    
    func saveBookIfNotExists(book: Book) async -> String? {
        // Attempt to save the book and retrieve the Firestore ID
        if let firestoreId = await firestoreService.saveBookIfNotExists(book: book) {
            // Since both `book.id` and `firestoreId` are not nil here, we can use them safely.
            // Update the book's Firestore ID and fetch data.
            self.book.firestoreId = firestoreId
            await fetchBookData(bookID: book.id, firestoreId: firestoreId, fromAPI: isFromAPI)
            return firestoreId
        } else {
            print("Failed to save or find the book in Firestore.")
            return nil
        }
    }
    
    func fetchBookData(bookID: String?, firestoreId: String?, fromAPI: Bool, resultsVM: ResultsListViewModel? = nil) async {
        guard let bookID = bookID, !bookID.isEmpty else {
            fetchError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid Book ID"])
            return
        }
        print("Fetching data for Book ID: \(bookID) with Firestore ID: \(String(describing: firestoreId)) from API: \(fromAPI)")
        self.isFromAPI = fromAPI
        if fromAPI {
            await resultsVM?.fetchBookFromAPI(bookID: bookID)
            if let error = resultsVM?.fetchError {
                DispatchQueue.main.async {
                    self.fetchError = error
                }
            } else if let fetchedBook = resultsVM?.fetchedBook?.book {
                DispatchQueue.main.async {
                    self.book = fetchedBook
                    self.dataFetched = true
                }
            }
        } else if let firestoreId = firestoreId {
            // If the book is not from API and a firestoreId is provided, attempt to fetch from Firestore
            do {
                if let fetchedBook = try await firestoreService.fetchBook(byID: firestoreId) {
                    DispatchQueue.main.async {
                        self.book = fetchedBook
                        self.dataFetched = true
                    }
                } else {
                    print("Did not find a book with firestoreId: \(firestoreId)")
                }
            } catch {
                DispatchQueue.main.async {
                    self.fetchError = error
                }
            }
        }
    }
    
    func resetDataFetchedFlag() {
        DispatchQueue.main.async {
            self.dataFetched = false
        }
    }
    
    func checkAndSetFirestoreIdForBook(book: Book) async -> String? {
            if await bookExists(isbn10: book.isbn10, isbn13: book.isbn13) {
                return await firestoreService.bookExists(isbn10: book.isbn10, isbn13: book.isbn13)
            } else {
                return nil
            }
        }
}
