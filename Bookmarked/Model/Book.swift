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
    var publisher: String?
    var isbn10: String?
    var isbn13: String?
    var imageUrl: String?
    var pageCount: Int?
    var categories: [String]?
    
    init(id: String? = nil,
         title: String = "",
         author: String = "Unknown Author",
         description: String? = nil,
         publishedDate: String? = nil,
         publisher: String? = nil,
         isbn10: String? = nil,
         isbn13: String? = nil,
         imageUrl: String? = nil,
         pageCount: Int? = nil,
         categories: [String]? = nil) {
        self.id = id
        self.title = title
        self.author = author
        self.description = description
        self.publishedDate = publishedDate
        self.publisher = publisher
        self.isbn10 = isbn10
        self.isbn13 = isbn13
        self.imageUrl = imageUrl
        self.pageCount = pageCount
        self.categories = categories
    }
}

extension Book {
    var dictionary: [String: Any] {
        return [
            "title": title,
            "author": author,
            "description": description ?? "",
            "publishedDate": publishedDate ?? "",
            "publisher": publisher ?? "",
            "isbn10": isbn10 ?? "",
            "isbn13": isbn13 ?? "",
            "imageUrl": imageUrl ?? "",
            "pageCount": pageCount ?? "",
            "categories": categories ?? []
        ]
    }
}


