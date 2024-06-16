//
//  ListView.swift
//  Bookmarked
//
//  Created by Vivien on 8/22/23.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseFirestoreSwift

extension DateFormatter {
    static let relativeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()
}

struct ActivityPostView: View {
    var item: ActivityFeedItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            if let imageUrl = item.book?.imageUrl, let url = URL(string: imageUrl) {
                WebImage(url: url)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60)
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text("\(item.displayEmail) \(item.type == .review ? "added a review:" : "favorited:")")
                    .font(.callout)
                    .italic(true)
                    .foregroundColor(.primary)
                
                Text(item.book?.title ?? "Default Title")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                //.padding(.top)
                Text(item.book?.author ?? "Default Author")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                if let timestamp = item.timestamp {
                    Text(DateFormatter.relativeFormatter.string(from: timestamp))
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }
}


struct ListView: View {
    @FirestoreQuery(collectionPath: "activityFeed") var feedItems: [ActivityFeedItem]
    @EnvironmentObject var favoritesVM: FavoritesViewModel
    @EnvironmentObject var bookVM: BookViewModel
    @State private var navigateToBookDetail = false
    @State private var selectedBookForDetail: Book?
    @State private var sheetIsPresented = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Group {
                if feedItems.isEmpty {
                    // Empty state view
                    VStack {
                        Image(systemName: "book.closed")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                            .opacity(0.5)
                        Text("No activities yet")
                            .font(.title)
                            .foregroundColor(.gray)
                    }
                    .padding()
                } else {
                    // Normal list view
                    List {
                        ForEach(feedItems, id: \.id) { item in
                            Button(action: {
                                fetchAndPrepareForNavigation(item: item)
                            }) {
                                ActivityPostView(item: item)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .navigationDestination(isPresented: $navigateToBookDetail) {
                        if let selectedBook = selectedBookForDetail {
                            BookDetailView(book: selectedBook, resultsVM: ResultsListViewModel(), bookID: selectedBook.id ?? "", activityType: .review, fromAPI: false).environmentObject(bookVM)
                        }
                    }
                }
            }
            .navigationTitle("Activity Stream")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                leadingToolbarItem
                trailingToolbarItem
            }
            .sheet(isPresented: $sheetIsPresented) {
                BookSearchView(book: Book())
            }
        }
    }
    
    func fetchAndPrepareForNavigation(item: ActivityFeedItem) {
        guard let bookIdFromActivity = item.book?.id else {
            print("Book ID not available")
            return
        }
        
        // Print to confirm the bookIdFromActivity value right after it's obtained.
        print("Attempting to fetch book details for book ID: \(bookIdFromActivity)")
        
        Task {
            await bookVM.fetchBookData(bookID: bookIdFromActivity, firestoreId: bookIdFromActivity, fromAPI: false)
            
            // Print to check if we entered the fetchBookData function
            print("fetchBookData initiated for book ID: \(bookIdFromActivity)")
            
            if let fetchError = bookVM.fetchError {
                print("Error fetching book details: \(fetchError.localizedDescription)")
            } else {
                // Print to confirm the book's title and ID if fetchBookData was successful
                print("Book details fetched successfully for book: \(bookVM.book.title), ID: \(String(describing: bookVM.book.id)), firestoreID: \(String(describing: bookVM.book.firestoreId))")
                
                selectedBookForDetail = bookVM.book
                navigateToBookDetail = true
                
                // Print to confirm navigation attempt
                print("Navigating to BookDetailView with book: \(bookVM.book.title), ID: \(String(describing: bookVM.book.id))")
            }
        }
    }

    
    private var leadingToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Sign Out") {
                do {
                    try Auth.auth().signOut()
                    dismiss()
                } catch {
                    print("Error: Could not sign out.")
                }
            }
        }
    }
    
    private var trailingToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                sheetIsPresented.toggle()
            } label: {
                Image(systemName: "magnifyingglass")
            }
        }
    }
}

struct ListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ListView()
        }
    }
}


