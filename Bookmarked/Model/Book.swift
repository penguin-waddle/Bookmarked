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
    var title: String
    var author: String
    var description: String?
    var publishedDate: String?
    var imageUrl: String?
    
    init(id: String? = nil,
         title: String = "",
         author: String = "Unknown Author",
         description: String? = nil,
         publishedDate: String? = nil,
         imageUrl: String? = nil) {
        self.id = id
        self.title = title
        self.author = author
        self.description = description
        self.publishedDate = publishedDate
        self.imageUrl = imageUrl
    }
}

extension Book {
    var dictionary: [String: Any] {
        return [
            "title": title,
            "author": author,
            "description": description ?? "",
            "publishedDate": publishedDate ?? "",
            "imageUrl": imageUrl ?? ""
        ]
    }
}


