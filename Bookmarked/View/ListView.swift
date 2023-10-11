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

struct ActivityPostView: View {
    var item: ActivityFeedItem
    
    var body: some View {
        HStack(alignment: .top) {
            if let imageUrl = item.book.imageUrl, let url = URL(string: imageUrl) {
                WebImage(url: url)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60)
                    .cornerRadius(8)
            }
            VStack(alignment: .leading) {
                Text("\(item.userID) \(item.type == .review ? "added a review" : "favorited")")
                    .font(.headline)
                Text(item.book.title)
                    .font(.subheadline)
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }
}


struct ListView: View {
    @FirestoreQuery(collectionPath: "activityFeed") var feedItems: [ActivityFeedItem]
    @State private var sheetIsPresented = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List(feedItems) { item in
                NavigationLink {
                    BookDetailView(book: item.book)
                } label: {
                    ActivityPostView(item: item)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Book Reviews")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Sign Out") {
                        do {
                            try Auth.auth().signOut()
                            print("Log out successful!")
                            dismiss()
                        } catch {
                            print("Error: Could not sign out.")
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        sheetIsPresented.toggle()
                    } label: {
                        Image(systemName: "plus")
                    }
                    
                }
            }
            .sheet(isPresented: $sheetIsPresented) {
                BookSearchView(book: Book())
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
