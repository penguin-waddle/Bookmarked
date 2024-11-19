//
//  UserReviewWithBookView.swift
//  Bookmarked
//
//  Created by Vivien on 7/9/24.
//

import SwiftUI
import SDWebImageSwiftUI
import ExpandableText

struct UserReviewWithBookView: View {
    var bookID: String
    var book: Book
    var review: Review
    var isEditing: Bool
    var onEdit: () -> Void
    var onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(alignment: .top) {
                WebImage(url: URL(string: book.imageUrl ?? ""))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60)
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 5) {
                    Text(review.title)
                        .font(.title3)
                        .fontWeight(.light)
                    StarsSelectionView(rating: .constant(review.rating), interactive: false, font: .callout)
                    ExpandableText(text: review.body)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                }
                Spacer()
            }
            .padding(.vertical, 5)

            if isEditing {
                HStack(spacing: 20) {
                    Button(action: {
                        print("Edit button tapped")
                        onEdit()  // Trigger the review sheet action
                    }) {
                        Image(systemName: "pencil")
                            .padding(10)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }

                    Button(action: {
                        print("Delete button tapped")
                        onDelete()
                    }) {
                        Image(systemName: "trash")
                            .padding(10)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .buttonStyle(BorderlessButtonStyle())
                .padding(.trailing, 10)
                .padding(.top, 5)
            }
        }
    }
}






#Preview {
    @State var showDeleteAlert = false
    @State var showingReviewSheet = false

    // Instantiate view models
    let userVM = UserViewModel(firestoreService: FirestoreService.shared)
    let reviewVM = ReviewViewModel(firestoreService: FirestoreService.shared)

    // Populate data for preview
    userVM.user = User(
        id: "1234",
        name: "Vivien",
        username: "vivreads",
        email: "vivien@gmail.com",
        password: "1234",
        profilePictureURL: "",
        bio: "hello this is bio",
        favorites: ["nil"],
        reviews: [ReviewReference(bookID: "2323", reviewID: "56576")],
        readLists: ["nil"],
        followers: ["nil"],
        following: ["nil"]
    )

    userVM.reviews = [
        Review(
            id: "56576",
            title: "Great book!",
            body: "Made me cry, lots of emotional moments. Only critique are the plot holes.",
            rating: 4,
            reviewer: "vivien@gmail.com",
            postedOn: Date(),
            userId: "1234",
            bookID: "2323"
        )
    ]

    userVM.reviewBooks = [
        "2323": Book(
            id: "2323",
            title: "Sample Book",
            author: "Author Name",
            description: "Sample description",
            publishedDate: "2021-03-16",
            publisher: "Publisher Name",
            isbn10: "1234567890",
            isbn13: "1234567890123",
            imageUrl: "http://example.com/image.jpg",
            pageCount: 100,
            categories: ["Fiction"]
        )
    ]

    return UserReviewWithBookView(
        bookID: "2323",
        book: userVM.reviewBooks["2323"]!,
        review: userVM.reviews.first!,
        isEditing: true,
        onEdit: { print("Edit tapped") },
        onDelete: { print("Delete tapped") }
    )
    .environmentObject(userVM)
    .environmentObject(reviewVM)
    // Optionally add the alert presentation to preview it in action:
    .alert(isPresented: $showDeleteAlert) {
        Alert(
            title: Text("Delete Review"),
            message: Text("Are you sure you want to delete this review?"),
            primaryButton: .destructive(Text("Delete")) {
                print("Review deleted.")
            },
            secondaryButton: .cancel()
        )
    }
}




