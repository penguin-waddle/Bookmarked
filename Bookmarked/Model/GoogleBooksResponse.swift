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
        let publisher: String?
        let description: String?
        let imageLinks: ImageLinks?
        let industryIdentifiers: [IndustryIdentifier]?
        
        struct ImageLinks: Codable {
            let smallThumbnail: String
            let thumbnail: String
        }
        
        struct IndustryIdentifier: Codable {
            let type: String
            let identifier: String
        }
    }
}



