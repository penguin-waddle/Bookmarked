//
//  Webservice.swift
//  Bookmarked
//
//  Created by Vivien on 8/28/23.
//

import Foundation

enum NetworkError: Error {
    case badURL
    case unexpectedStatusCode(Int)
    case decodingError(Error)
}

extension String {
    func trimmed() -> String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

class Webservice {
    
    func getBooks(searchTerm: String, country: String) async throws -> [GoogleBookItem] {
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.googleapis.com"
        components.path = "/books/v1/volumes"
        components.queryItems = [
            URLQueryItem(name: "q", value: searchTerm.trimmed()),
            URLQueryItem(name: "key", value: "AIzaSyCGVqKsuNzdzBXQE5BcKfX_xkinEKFkRYg"),
            URLQueryItem(name: "country", value: country)
        ]
        
        guard let url = components.url else {
            throw NetworkError.badURL
        }
        
        print("Constructed URL:", url)
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unexpectedStatusCode((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        if httpResponse.statusCode != 200 {
            throw NetworkError.unexpectedStatusCode(httpResponse.statusCode)
        }
        
        do {
            let googleBooksResponse = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
            return googleBooksResponse.items
        } catch let decodingError {
            throw NetworkError.decodingError(decodingError)
        }
    }
}
