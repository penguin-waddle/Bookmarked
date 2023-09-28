//
//  BookSearchView.swift
//  Bookmarked
//
//  Created by Vivien on 8/23/23.
//

import SwiftUI

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            TextField("Searching for...", text: $text)
                .padding(7)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
        .padding(.horizontal, 10)
    }
}


struct BookSearchView: View {
    @EnvironmentObject var bookVM: BookViewModel
    @State var book: Book
    @State private var showBookDetail = false
    @State private var selectedBook: Book?
    
    @State private var searchText: String = ""
    @StateObject private var resultsListVM = ResultsListViewModel()
    
    var body: some View {
            NavigationView {
                VStack {
                    SearchBar(text: $searchText)
                        .padding(.horizontal)
                    
                        List(resultsListVM.books, id: \.id) { resultViewModel in
                            NavigationLink(
                                destination: BookDetailView(book: resultViewModel.book),
                                label: {
                                    HStack {
                                        // Check and fetch the thumbnail
                                        if let thumbnail = resultViewModel.image, let url = URL(string: thumbnail) {
                                            AsyncImage(url: url) { image in
                                                image.resizable()
                                                    .scaledToFit()
                                            } placeholder: {
                                                ProgressView()
                                            }
                                            .frame(width: 50, height: 80)
                                        } else {
                                            Rectangle()
                                                .fill(Color.gray)
                                                .frame(width: 50, height: 80)
                                        }
                                        
                                        VStack(alignment: .leading) {
                                            Text(resultViewModel.title)
                                            Text(resultViewModel.authors)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                                )
                                .onTapGesture {
                                    selectBook(from: resultViewModel.book)
                                }
                        }
                        .listStyle(.plain)
                        .onChange(of: searchText) { value in
                            Task {
                                if !value.isEmpty && value.count > 3 {
                                    await resultsListVM.search(name: value)
                                } else {
                                    resultsListVM.books.removeAll()
                                }
                            }
                    }
                }
                .navigationTitle("Books")
                .navigationBarTitleDisplayMode(.inline)
            }
        }

    func selectBook(from book: Book) {
        // Since you already have a book instance, you can bypass the conversion.
        // Use BookViewModel to save this book to Firestore
        Task {
            let success = await bookVM.saveBookIfNotExists(book: book)
            if success {
                print("Success adding book!")
                selectedBook = book
                // Ensure the book is set before showing details.
                guard selectedBook != nil else { return }
                showBookDetail = true
            } else {
                print("Error saving book!")
            }
        }
    }


}

struct BookSearchView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            BookSearchView(book: Book())
                .environmentObject(BookViewModel())
        }
    }
}
