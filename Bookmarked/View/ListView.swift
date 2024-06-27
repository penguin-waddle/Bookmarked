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
    @State private var sheetIsPresented = false
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: ActivityFeedItem?
    @State private var isBookDetailViewPresented = false
    @State private var selectedBook: Book?

    var body: some View {
        NavigationStack {
            Group {
                if feedItems.isEmpty {
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
                    List {
                        ForEach(feedItems, id: \.id) { item in
                            Button(action: {
                                selectedItem = item
                                fetchBook(bookID: item.bookID)
                            }) {
                                ActivityPostView(item: item)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Activity Stream")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                leadingToolbarItem
                trailingToolbarItem
            }
            .sheet(isPresented: $sheetIsPresented) {
                BookSearchView()
            }
            .navigationDestination(isPresented: $isBookDetailViewPresented) {
                if let selectedItem = selectedItem, let selectedBook = selectedBook {
                    BookDetailView(
                        bookVM: bookVM,
                        resultsVM: ResultsListViewModel(),
                        book: selectedBook,
                        bookID: selectedItem.bookID,
                        activityType: selectedItem.type,
                        fromAPI: false,
                        fromListView: true
                    )
                }
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
    
    private func fetchBook(bookID: String) {
        Task {
            do {
                if let book = try await FirestoreService.shared.fetchBook(byID: bookID) {
                    DispatchQueue.main.async {
                        self.selectedBook = book
                        self.isBookDetailViewPresented = true
                    }
                } else {
                    print("Document does not exist")
                }
            } catch {
                print("Error fetching book: \(error.localizedDescription)")
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
