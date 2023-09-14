//
//  ResultsViewModel.swift
//  Bookmarked
//
//  Created by Vivien on 8/28/23.
//

import Foundation

@MainActor
class ResultsListViewModel: ObservableObject {
    
    @Published var books: [ResultsViewModel] = []
    
    func search(name: String) async {
        do {
            let countryCode = NSLocale.current.language.region?.identifier ?? "US"
            let books = try await Webservice().getBooks(searchTerm: name, country: countryCode)
            self.books = books.map(ResultsViewModel.init)
        } catch {
            print(error)
        }
    }
}

struct ResultsViewModel: Identifiable {
    let book: Book
    
    var id: String? {
        return book.id
    }

    init(googleBookItem: GoogleBookItem) {
        self.book = Book(
            id: googleBookItem.id,
            title: googleBookItem.volumeInfo.title,
            author: !googleBookItem.volumeInfo.authors.isEmpty ? googleBookItem.volumeInfo.authors.joined(separator: ", ") : "Unknown Author",
            description: googleBookItem.volumeInfo.description,
            publishedDate: googleBookItem.volumeInfo.publishedDate,
            imageUrl: googleBookItem.volumeInfo.imageLinks?.thumbnail
        )
    }

    var title: String {
        return book.title
    }

    var authors: String {
        return book.author
    }

    var image: String? {
        return book.imageUrl
    }
}
