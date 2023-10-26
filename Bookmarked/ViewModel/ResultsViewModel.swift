//
//  ResultsViewModel.swift
//  Bookmarked
//
//  Created by Vivien on 8/28/23.
//

import Foundation

@MainActor
class ResultsListViewModel: ObservableObject {
    
    private var webService: WebServiceProvider
      
      init(webService: WebServiceProvider = Webservice()) {
          self.webService = webService
      }
    
    @Published var books: [ResultsViewModel] = []
    @Published var fetchedBook: ResultsViewModel?
    
    func search(name: String) async {
        do {
            let countryCode = NSLocale.current.region?.identifier ?? "US"
            let books = try await webService.getBooks(searchTerm: name, country: countryCode)
            self.books = books.map(ResultsViewModel.init)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func fetchBookFromAPI(bookID: String) async {
        do {
            let countryCode = NSLocale.current.region?.identifier ?? "US"
            if let googleBookItem = try await webService.getBookByID(bookID: bookID, country: countryCode) {
                let fetchedBook = ResultsViewModel(googleBookItem: googleBookItem)
                self.fetchedBook = fetchedBook
            }
        } catch {
            print(error.localizedDescription)
        }
    }

}

struct ResultsViewModel: Identifiable {
    let book: Book
    
    var id: String? {
        return book.id
    }

    init(googleBookItem: GoogleBookItem) {
        let isbn10 = googleBookItem.volumeInfo.industryIdentifiers?.first(where: { $0.type == "ISBN_10" })?.identifier
        let isbn13 = googleBookItem.volumeInfo.industryIdentifiers?.first(where: { $0.type == "ISBN_13" })?.identifier
        
        self.book = Book(
            id: googleBookItem.id,
            title: googleBookItem.volumeInfo.title,
            author: !googleBookItem.volumeInfo.authors.isEmpty ? googleBookItem.volumeInfo.authors.joined(separator: ", ") : "Unknown Author",
            description: googleBookItem.volumeInfo.description,
            publishedDate: googleBookItem.volumeInfo.publishedDate,
            publisher: googleBookItem.volumeInfo.publisher,
            isbn10: isbn10,
            isbn13: isbn13,
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

