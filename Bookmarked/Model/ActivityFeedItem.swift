//
//  ActivityFeedItem.swift
//  Bookmarked
//
//  Created by Vivien on 10/9/23.
//

import Foundation
import FirebaseFirestoreSwift

enum ActivityType: String, Codable {
    case review, favorite
}

struct ActivityFeedItem: Identifiable, Codable {
    @DocumentID var id: String?
    var userID: String
    var userEmail: 
    var book: Book
    var type: ActivityType
}
