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
        
    init(service: FirestoreServiceProtocol = FirestoreService()) {
        self.firestoreService = service
    }
    
    @Published var book = Book()
    
    func saveBook(book: Book) async -> Bool {
        return await firestoreService.saveBook(book)
    }

    func bookExists(isbn10: String?, isbn13: String?) async -> Bool {
        return await firestoreService.bookExists(isbn10: isbn10, isbn13: isbn13)
    }

    func saveBookIfNotExists(book: Book) async -> Bool {
        return await firestoreService.saveBookIfNotExists(book: book)
    }

}
