//
//  BookDetailView.swift
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

struct BookDetailView: View {
    @EnvironmentObject var bookVM: BookViewModel
    @State var book: Book
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText: String = ""
    @StateObject private var resultsListVM = ResultsListViewModel()
    
    var body: some View {
            NavigationView {
                VStack {
                    SearchBar(text: $searchText)
                        .padding(.horizontal)
                    
                    List(resultsListVM.books, id: \.id) { resultViewModel in
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
            }
            .navigationTitle("Books")
            .navigationBarTitleDisplayMode(.inline)
        }

    func selectBook(from book: Book) {
        // Since you already have a book instance, you can bypass the conversion.
        // Use BookViewModel to save this book to Firestore
        Task {
            let success = await bookVM.saveBook(book: book)
            if success {
                print("Success adding book!")
                // Dismiss the detail view
                dismiss()
            } else {
                print("Error saving book!")
            }
        }
    }


}

struct BookDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            BookDetailView(book: Book())
                .environmentObject(BookViewModel())
        }
    }
}
