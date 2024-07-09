//
//  UserProfileView.swift
//  Bookmarked
//
//  Created by Vivien on 1/15/24.
//
import FirebaseFirestore
import FirebaseAuth
import SwiftUI
import SDWebImageSwiftUI
import SlidingTabView

struct UserReviewsListView: View {
    @ObservedObject var reviewViewModel: ReviewViewModel
    var userId: String

    var body: some View {
        List(reviewViewModel.reviews, id: \.id) { review in
            if let bookID = review.bookID {
                NavigationLink(destination: BookDetailViewWrapper(book: Book(), bookID: bookID)) {
                    BookReviewRowView(review: review)
                }
            }
        }
        .onAppear {
            print("UserReviewsListView onAppear called with reviews: \(reviewViewModel.reviews)")
            Task {
                await reviewViewModel.fetchReviewsForUser(userId: userId)
                print("Fetched reviews: \(reviewViewModel.reviews)")
            }
        }
        .onChange(of: reviewViewModel.reviews) { newReviews in
            print("Reviews updated: \(newReviews)")
        }
    }
}

struct UserProfileView: View {
    @ObservedObject var userVM: UserViewModel
    @StateObject var reviewViewModel = ReviewViewModel()
    @StateObject var favoritesViewModel = FavoritesViewModel()
    @State private var tabIndex = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 20) {
                // Profile picture
                WebImage(url: URL(string: userVM.user?.profilePictureURL ?? ""))
                    .resizable()
                    .placeholder {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 75))
                            )
                            .frame(width: 150, height: 150)
                    }
                    .indicator(.activity)
                    .transition(.fade(duration: 0.5))
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .clipShape(Circle())
                    .padding(.top)

                // User's name and username
                Text(userVM.user?.name ?? "Name")
                    .font(.title)
                    .fontWeight(.bold)
                Text("@\(userVM.user?.username ?? "username")")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                // Bio
                Text(userVM.user?.bio ?? "No Bio")
                    .font(.body)
                    .padding(.horizontal)

                // Metrics
                HStack(spacing: 100) {
                    MetricView(title: "Followers", value: "\(userVM.user?.followers.count ?? 0)")
                    MetricView(title: "Following", value: "\(userVM.user?.following.count ?? 0)")
                }

                // Tabs for bookshelves (Reviews, Favorites)
                VStack {
                    SlidingTabView(selection: $tabIndex,
                                    tabs: ["Reviews (\(reviewViewModel.reviews.count))",
                                           "Favorites (\(favoritesViewModel.favorites.count))"],
                                    animation: .easeInOut)
                    
                    if tabIndex == 0 {
                        UserReviewsListView(reviewViewModel: reviewViewModel, userId: userVM.user?.id ?? "")
                    } else if tabIndex == 1 {
                        BookShelfView(books: favoritesViewModel.favorites)
                    }
                }
                .padding(.horizontal)
                Spacer()
            }
            .padding(.top, 40)
            .padding(.horizontal)
        }
        .onAppear {
            let userId = Auth.auth().currentUser?.uid ?? ""
            userVM.fetchUserData(userId: userId)

            Task {
                await reviewViewModel.fetchReviewsForUser(userId: userId)
                await favoritesViewModel.fetchFavorites(userId: userId)
            }
        }
    }
}


#Preview {
    UserProfileView(userVM: UserViewModel())
}

