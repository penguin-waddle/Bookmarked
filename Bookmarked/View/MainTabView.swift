//
//  MainTabView.swift
//  Bookmarked
//
//  Created by Vivien on 6/27/24.
//

import SwiftUI

struct MainTabView: View {
    @StateObject var favoritesVM = FavoritesViewModel()
    @StateObject var reviewVM = ReviewViewModel()
    @StateObject var bookVM = BookViewModel()
    @StateObject var userVM = UserViewModel()

    var body: some View {
        TabView {
            ListView()
                .tabItem {
                    Label("Activity Feed", systemImage: "list.bullet")
                }
                .environmentObject(favoritesVM)
                .environmentObject(bookVM)

            BookSearchView()
                .tabItem {
                    Label("Discover", systemImage: "magnifyingglass")
                }
                .environmentObject(favoritesVM)
                .environmentObject(reviewVM)

            UserProfileView(userVM: userVM)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .environmentObject(userVM)
        }
    }
}

#Preview {
    MainTabView()
}

