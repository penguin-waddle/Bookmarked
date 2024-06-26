//
//  Review.swift
//  Bookmarked
//
//  Created by Vivien on 9/15/23.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift


struct Review: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var title = ""
    var body = ""
    var rating = 0
    var reviewer = Auth.auth().currentUser?.email ?? ""
    var postedOn = Date()
    var userId: String?
    var bookID: String?
    
    var dictionary: [String: Any] {
        return ["title": title, "body": body, "rating": rating, "reviewer": reviewer, "postedOn": Timestamp(date: postedOn),
                "userId": userId ?? Auth.auth().currentUser?.uid ?? "", "bookID": bookID ?? ""]
    }
}

extension Review: Equatable {
    static func == (lhs: Review, rhs: Review) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.body == rhs.body &&
               lhs.rating == rhs.rating &&
               lhs.reviewer == rhs.reviewer &&
               lhs.userId == rhs.userId &&
               lhs.bookID == rhs.bookID
    }
}


