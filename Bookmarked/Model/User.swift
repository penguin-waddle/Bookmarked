//
//  User.swift
//  Bookmarked
//
//  Created by Vivien on 1/12/24.
//

import Foundation

struct User: Identifiable, Hashable, Codable {
    var id: String
    var name: String
    var username: String
    var email: String
    var password: String
    var profilePictureURL: String
    var bio: String
    var favorites: [String]
    var reviews: [ReviewReference]
    var readLists: [String]
    var followers: [String]
    var following: [String]
}

struct ReviewReference: Codable, Hashable, Identifiable {
    var id: String {
            return reviewID
        }
    var bookID: String
    var reviewID: String
}

extension ReviewReference {
    var dictionary: [String: Any] {
        return ["bookID": bookID, "reviewID": reviewID]
    }
}

