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
    @Environment(\.dismiss) private var dismiss
    @State private var book = Book()
    @StateObject var favoritesVM = FavoritesViewModel()
    @StateObject var reviewVM = ReviewViewModel()
    @StateObject private var resultsListVM = ResultsListViewModel()

    @State private var searchText: String = ""
    @State private var selectedBookID: String?

    private var isShowingError: Binding<Bool> {
        .init(
            get: { self.resultsListVM.fetchError != nil },
            set: { _ in self.resultsListVM.fetchError = nil }
        )
    }

    var body: some View {
        NavigationStack {
            VStack {
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                List(resultsListVM.books, id: \.id) { resultViewModel in
                    NavigationLink(
                        value: resultViewModel.book.id ?? "nil",
                        label: {
                            BookRow(resultViewModel: resultViewModel)
                        }
                    )
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
            .navigationTitle("Search Books")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .alert("Error", isPresented: isShowingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(resultsListVM.fetchError?.localizedDescription ?? "An unknown error occurred during the search.")
            }
            .navigationDestination(for: String.self) { bookID in
                if let resultViewModel = resultsListVM.books.first(where: { $0.book.id == bookID }) {
                    createBookDetailView(for: resultViewModel)
                }
            }
        }
    }
    
    private func createBookDetailView(for resultViewModel: ResultsViewModel) -> some View {
        //print("Navigating to BookDetailView with bookID: \(String(describing: resultViewModel.id))")
        
        // Update the book state before navigation
        DispatchQueue.main.async {
            self.book = resultViewModel.book
        }

        let bookVM = BookViewModel()
        
        return BookDetailView(
            bookVM: bookVM,
            resultsVM: resultsListVM,
            book: resultViewModel.book,
            bookID: resultViewModel.book.id ?? "nil",
            activityType: .review,
            fromAPI: true,
            fromListView: false
        )
        .environmentObject(favoritesVM)
        .environmentObject(reviewVM)
    }
}

private struct BookRow: View {
    let resultViewModel: ResultsViewModel
    
    var body: some View {
        HStack {
            if let thumbnail = resultViewModel.image, let url = URL(string: thumbnail) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable()
                            .scaledToFit()
                    case .empty, .failure:
                        Rectangle()
                            .fill(Color.gray)
                            .frame(width: 50, height: 80)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 50, height: 80)
                .cornerRadius(8)
            } else {
                VStack {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.gray)
                    Text("No Image")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(width: 50, height: 80)
                .background(Color(.systemGray5))
                .cornerRadius(8)
            }
            
            VStack(alignment: .leading) {
                Text(resultViewModel.title)
                Text(resultViewModel.authors)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                Text(resultViewModel.publisher)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct BookSearchView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            BookSearchView()
                .environmentObject(BookViewModel())
                .environmentObject(FavoritesViewModel())
                .environmentObject(ReviewViewModel())
        }
    }
}
