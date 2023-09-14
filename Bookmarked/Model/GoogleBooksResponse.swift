//
//  GoogleBooksResponse.swift
//  Bookmarked
//
//  Created by Vivien on 8/28/23.
//

import Foundation

struct GoogleBooksResponse: Codable {
    let items: [GoogleBookItem]
}

struct GoogleBookItem: Codable {
    let id: String
    let volumeInfo: VolumeInfo
    
    struct VolumeInfo: Codable {
        let title: String
        let authors: [String]
        let publishedDate: String?
        let description: String?
        let imageLinks: ImageLinks?
        
        struct ImageLinks: Codable {
            let smallThumbnail: String
            let thumbnail: String
        }
    }

    
}



