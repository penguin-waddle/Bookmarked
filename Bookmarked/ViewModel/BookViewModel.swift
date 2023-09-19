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
}
