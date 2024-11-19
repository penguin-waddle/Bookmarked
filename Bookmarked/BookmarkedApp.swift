//
//  BookmarkedApp.swift
//  Bookmarked
//
//  Created by Vivien on 8/22/23.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct BookmarkedApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            LoginView()
                .environmentObject(BookViewModel(firestoreService: FirestoreService.shared))
                .environmentObject(FavoritesViewModel(firestoreService: FirestoreService.shared))
                .environmentObject(ReviewViewModel(firestoreService: FirestoreService.shared))
                .environmentObject(UserViewModel(firestoreService: FirestoreService.shared))
        }
    }
}

