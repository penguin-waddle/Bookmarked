//
//  UserViewModel.swift
//  Bookmarked
//
//  Created by Vivien on 1/12/24.
//

import Foundation
import FirebaseFirestore

class UserViewModel: ObservableObject {
    @Published var user: User?

    func fetchUserData(userId: String) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)

        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let userData = document.data()
                DispatchQueue.main.async {
                    self.user = User(
                        id: userId,
                        name: userData?["name"] as? String ?? "",
                        username: userData?["username"] as? String ?? "",
                        email: userData?["email"] as? String ?? "",
                        profilePictureURL: userData?["profilePictureURL"] as? String ?? "",
                        bio: userData?["bio"] as? String ?? "",
                        favorites: userData?["favorites"] as? [String] ?? [],
                        reviews: userData?["reviews"] as? [String] ?? [],
                        readLists: userData?["readLists"] as? [String] ?? []
                    )
                }
            } else {
                print("Document does not exist")
            }
        }
    }
    
    func updateUserData(updatedUser: User) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(updatedUser.id)
        
        userRef.setData([
            "name": updatedUser.name,
            "username": updatedUser.username,
            "email": updatedUser.email,
            "profilePictureURL": updatedUser.profilePictureURL,
            "bio": updatedUser.bio,
            "favorites": updatedUser.favorites,
            "reviews": updatedUser.reviews,
            "readLists": updatedUser.readLists
        ]) { error in
            if let error = error {
                print("Error updating user: \(error.localizedDescription)")
            } else {
                print("User successfully updated")
            }
        }
    }

}

