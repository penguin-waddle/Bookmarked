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
    @Published var book = Book()
    
    func saveBook(book: Book) async -> Bool {
        let db = Firestore.firestore()
        
        if let id = book.id { // book already exists, so save
            do {
                try await db.collection("books").document(id).setData(book.dictionary)
                print("Data updated successfully!")
                return true
            } catch {
                print("Error: Could not update data in 'books' \(error.localizedDescription)")
                return false
            }
        } else {
            do {
                try await db.collection("books").addDocument(data: book.dictionary)
                print("Data added successfully!")
                return true
            } catch {
                print("Error: Could not create a new book in 'books' \(error.localizedDescription)")
                return false
            }
        }
    }
    
    func bookExists(isbn10: String?, isbn13: String?) async -> Bool {
        let db = Firestore.firestore()
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
            return await saveBook(book: book)
        }
        return true
    }

}
