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
    @ObservedObject var resultsVM: ResultsListViewModel
    
    var body: some View {
        NavigationView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 20) {
                ForEach(books, id: \.self) { book in
                    NavigationLink(destination: BookDetailView(
                        resultsVM: resultsVM,
                        bookID: book.id ?? "",
                        activityType: .review, // Replace with appropriate enum value
                        fromAPI: false // Or true, based on context
                    )) {
                        Group {
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
                }
                .padding()
            }
        }
    }
}


#Preview {
    BookShelfView(books: [
            Book(title: "Sample Book 1", author: "Author 1"),
            Book(title: "Sample Book 2", author: "Author 2")
                // Add more sample books as needed
        ])
}
