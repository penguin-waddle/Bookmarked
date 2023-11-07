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
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}

@main
struct BookmarkedApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var bookVM = BookViewModel()
    
    var firestoreService: FirestoreService {
           return FirestoreService()
       }
    
    var body: some Scene {
        WindowGroup {
            LoginView()
                .environmentObject(bookVM)
                .environmentObject(firestoreService)
        }
    }
}
