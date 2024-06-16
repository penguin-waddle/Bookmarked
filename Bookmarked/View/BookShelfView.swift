//
//  BookShelfView.swift
//  Bookmarked
//
//  Created by Vivien on 1/15/24.
//

import SwiftUI
import SDWebImageSwiftUI

struct BookShelfView: View {
    var books: [Book]
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 20) {
            ForEach(books, id: \.self) { book in
                if let firestoreId = book.firestoreId {
                    NavigationLink(destination: BookDetailView(book: book, resultsVM: ResultsListViewModel(), bookID: firestoreId, activityType: .review, fromAPI: false)) {
                        bookThumbnailView(book)
                    }
                }
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private func bookThumbnailView(_ book: Book) -> some View {
        if let imageUrl = book.imageUrl, let url = URL(string: imageUrl) {
            WebImage(url: url)
                .resizable()
                .scaledToFit()
                .frame(width: 100)
                .cornerRadius(10)
        } else {
            Rectangle()
                .fill(Color.gray)
                .frame(width: 100, height: 150)
                .cornerRadius(8)
        }
    }
}


struct BookShelfView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleBooks = [
            Book(title: "Sample Book 1", author: "Author 1"),
            Book(title: "Sample Book 2", author: "Author 2"),
            Book(title: "Sample Book 3", author: "Author 3")
        ]

        BookShelfView(books: sampleBooks)
            .previewLayout(.sizeThatFits)
    }
}


