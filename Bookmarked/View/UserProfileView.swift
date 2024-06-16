//
//  UserProfileView.swift
//  Bookmarked
//
//  Created by Vivien on 1/15/24.
//
import FirebaseAuth
import SwiftUI
import SDWebImageSwiftUI

struct UserReviewsListView: View {
    @ObservedObject var reviewViewModel: ReviewViewModel
    var userID: String

    var body: some View {
        List(reviewViewModel.reviews, id: \.id) { review in
            NavigationLink(destination: ReviewView(book: reviewViewModel.reviewBooks[review.id ?? ""] ?? Book(), review: review)) {
                Text(review.title)
            }
        }
        .onAppear {
            Task {
                await reviewViewModel.fetchReviewsByUser(userID: userID)
            }
        }
    }
}

struct UserProfileView: View {
    @ObservedObject var userViewModel: UserViewModel
    @StateObject var reviewViewModel = ReviewViewModel()
    @StateObject var favoritesViewModel = FavoritesViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 10) {
                // Profile picture
                WebImage(url: URL(string: userViewModel.user?.profilePictureURL ?? ""))
                    .resizable()
                    .placeholder(Image(systemName: "person.circle"))
                    .indicator(.activity)
                    .transition(.fade(duration: 0.5))
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())

                // User's name and username
                Text(userViewModel.user?.name ?? "Name")
                    .font(.title)
                    .fontWeight(.bold)
                Text("@\(userViewModel.user?.username ?? "username")")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                // Bio
                Text(userViewModel.user?.bio ?? "No Bio")
                    .font(.body)
                    .padding()

                // Metrics
                HStack {
                    MetricView(title: "Reviews", value: "\(userViewModel.user?.reviews.count ?? 0)")
                    MetricView(title: "Favorites", value: "\(userViewModel.user?.favorites.count ?? 0)")
                    MetricView(title: "Readlists", value: "\(userViewModel.user?.readLists.count ?? 0)")
                }

                // Tabs for bookshelves (Reviews, Favorites, ReadLists)
                TabView {
                    UserReviewsListView(reviewViewModel: reviewViewModel, userID: userViewModel.user?.id ?? "")
                            .tabItem { Label("Reviews", systemImage: "star") }

                    BookShelfView(books: favoritesViewModel.favorites)
                            .tabItem { Label("Favorites", systemImage: "heart") }
                }
                .frame(height: 300)
            }
        }
        .onAppear {
            let userID = Auth.auth().currentUser?.uid ?? ""
            userViewModel.fetchUserData(userId: userID)

            Task {
                await reviewViewModel.fetchReviewsByUser(userID: userID)
                await favoritesViewModel.fetchFavorites(userId: userID)
            }
        }
    }
}


#Preview {
    UserProfileView(userViewModel: UserViewModel())
}
