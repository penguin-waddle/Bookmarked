//
//  BookShelfView.swift
//  Bookmarked
//
//  Created by Vivien on 1/15/24.
//
import SwiftUI
import SDWebImageSwiftUI
import FirebaseAuth

struct BookShelfView: View {
    var books: [Book]
    @EnvironmentObject var userVM: UserViewModel

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 20) {
                ForEach(books) { book in
                    NavigationLink(destination: BookDetailViewWrapper(book: book, bookID: book.firestoreId ?? "")) {
                        BookThumbnailView(book: book)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            print("BookShelfView appeared with books: \(books)")
        }
    }
}

struct BookThumbnailView: View {
    var book: Book

    var body: some View {
        VStack {
            if let imageUrl = book.imageUrl, let url = URL(string: imageUrl) {
                WebImage(url: url)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 150)
                    .cornerRadius(10)
            } else {
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 100, height: 150)
                    .cornerRadius(8)
            }
            Text(book.title)
                .font(.caption)
                .lineLimit(1)
        }
    }
}


struct BookDetailViewWrapper: View {
    @EnvironmentObject var bookVM: BookViewModel
    @EnvironmentObject var favoritesVM: FavoritesViewModel
    @EnvironmentObject var reviewVM: ReviewViewModel
    @EnvironmentObject var userVM: UserViewModel

    let book: Book
    let bookID: String

    var body: some View {
        BookDetailView(
            bookVM: bookVM,
            resultsVM: ResultsListViewModel(),
            book: book,
            bookID: bookID,
            activityType: .review,
            fromAPI: false,
            fromListView: true
        )
        .onAppear {
            Task {
                if let fetchedBook = try? await FirestoreService.shared.fetchBook(byID: bookID) {
                    DispatchQueue.main.async {
                        bookVM.book = fetchedBook
                    }
                }
                favoritesVM.checkIfBookIsFavorite(userId: Auth.auth().currentUser?.uid ?? "", firestoreId: bookID)
                await reviewVM.fetchReviews(for: bookID)
            }
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
            .environmentObject(BookViewModel())
            .environmentObject(FavoritesViewModel())
            .environmentObject(ReviewViewModel())
            .environmentObject(UserViewModel())
    }
}

