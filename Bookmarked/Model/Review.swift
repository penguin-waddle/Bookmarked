//
//  Review.swift
//  Bookmarked
//
//  Created by Vivien on 9/15/23.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift


struct Review: Identifiable, Codable {
    @DocumentID var id: String?
    var title = ""
    var body = ""
    var rating = 0
    var reviewer = Auth.auth().currentUser?.email ?? ""
    var postedOn = Date()
    
    var dictionary: [String: Any] {
        return ["title": title, "body": body, "rating": rating, "reviewer": reviewer, "postedOn": Timestamp(date: Date())]
    }
}
