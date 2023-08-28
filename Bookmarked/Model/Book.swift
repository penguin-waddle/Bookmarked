//
//  Book.swift
//  Bookmarked
//
//  Created by Vivien on 8/23/23.
//

import Foundation
import FirebaseFirestoreSwift

struct Book: Identifiable, Codable {
    @DocumentID var id: String?
    var title = ""
    var author = ""
    
    var dictionary: [String: Any] {
        return ["title": title, "author": author]
    }
}
