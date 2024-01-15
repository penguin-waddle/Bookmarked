//
//  UserProfileView.swift
//  Bookmarked
//
//  Created by Vivien on 1/15/24.
//

import SwiftUI
import SDWebImageSwiftUI

struct UserProfileView: View {
    @ObservedObject var userViewModel: UserViewModel

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
                    BookShelfView(books: userViewModel.user?.reviews ?? [])
                        .tabItem { Label("Reviews", systemImage: "star") }
                    BookShelfView(books: userViewModel.user?.favorites ?? [])
                        .tabItem { Label("Favorites", systemImage: "heart") }
                    BookShelfView(books: userViewModel.user?.readLists ?? [])
                        .tabItem { Label("ReadLists", systemImage: "list.bullet") }
                }
                .frame(height: 300)
            }
        }
    }
}


#Preview {
    UserProfileView(userViewModel: UserViewModel())
}
