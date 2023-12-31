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
    
    @State private var searchText: String = ""
    @StateObject private var resultsListVM = ResultsListViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                // Book List
                List(resultsListVM.books, id: \.id) { resultViewModel in
                    NavigationLink {
                        BookDetailView(resultsVM: resultsListVM,
                                       bookID: resultViewModel.book.id ?? "",
                                       activityType: .review,
                                       fromAPI: true)
                    }
                label: {
                    BookRow(resultViewModel: resultViewModel)
                    }
                .onTapGesture {
                    print("Navigating to details for book: \(String(describing: resultViewModel.book.id))")
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
            .navigationTitle("Search Books")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
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
        }
    }
}
