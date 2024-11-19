//
//  MainTabView.swift
//  Bookmarked
//
//  Created by Vivien on 6/27/24.
//

import SwiftUI

struct MainTabView: View {
    @StateObject var favoritesVM = FavoritesViewModel(firestoreService: FirestoreService.shared)
    @StateObject var reviewVM = ReviewViewModel(firestoreService: FirestoreService.shared)
    @StateObject var bookVM = BookViewModel(firestoreService: FirestoreService.shared)
    @StateObject var userVM = UserViewModel(firestoreService: FirestoreService.shared)

    var body: some View {
        TabView {
            ListView()
                .tabItem {
                    Label("Activity Feed", systemImage: "list.bullet")
                }
                .environmentObject(favoritesVM)
                .environmentObject(bookVM)
                .environmentObject(reviewVM)
                .environmentObject(userVM)

            BookSearchView()
                .tabItem {
                    Label("Discover", systemImage: "magnifyingglass")
                }
                .environmentObject(favoritesVM)
                .environmentObject(reviewVM)
                .environmentObject(userVM)

            UserProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .environmentObject(favoritesVM)
                .environmentObject(reviewVM)
                .environmentObject(bookVM)
                .environmentObject(userVM)
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(UserViewModel(firestoreService: FirestoreService.shared))
}


