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
    @Environment(\.dismiss) private var dismiss
    @State var book: Book
    @EnvironmentObject var favoritesVM: FavoritesViewModel
    @StateObject private var resultsListVM = ResultsListViewModel()

    @State private var searchText: String = ""

    private var isShowingError: Binding<Bool> {
        .init(
            get: { self.resultsListVM.fetchError != nil },
            set: { _ in self.resultsListVM.fetchError = nil }
        )
    }

    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                List(resultsListVM.books, id: \.id) { resultViewModel in
                    NavigationLink(destination: {
                        //print("Navigating to BookDetailView with bookID from API: \(resultViewModel.id ?? "N/A")")
                        return BookDetailView(book: resultViewModel.book, resultsVM: resultsListVM, bookID: resultViewModel.id ?? "", activityType: .review, fromAPI: true)
                    }(), label: {
                        BookRow(resultViewModel: resultViewModel)
                    })
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
        }
    }
}


private struct BookRow: View {
    let resultViewModel: ResultsViewModel
    
    var body: some View {
        HStack {
            // Thumbnail
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
            }
            else {
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 50, height: 80)
                    .cornerRadius(8)
            }
            
            // Book Info
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
            BookSearchView(book: Book())
                .environmentObject(BookViewModel())
                .environmentObject(FavoritesViewModel())
        }
    }
}

