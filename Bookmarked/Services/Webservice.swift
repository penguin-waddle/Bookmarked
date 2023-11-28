//
//  Webservice.swift
//  Bookmarked
//
//  Created by Vivien on 8/28/23.
//
import Firebase
import FirebaseFunctions
import Foundation

protocol WebServiceProvider {
    func getBooks(searchTerm: String, country: String) async throws -> [GoogleBookItem]
    func getBookByID(bookID: String, country: String) async throws -> GoogleBookItem?
}

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

class Webservice: WebServiceProvider {
    lazy var functions = Functions.functions()

    func getBooks(searchTerm: String, country: String) async throws -> [GoogleBookItem] {
        do {
            let result = try await functions.httpsCallable("getBooks").call(["searchTerm": searchTerm, "country": country])
            guard let data = result.data as? [String: Any], let items = data["items"] as? [[String: Any]] else {
                let error = NSError(domain: "DecodingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Decoding error in getBooks"])
                //print("Error in getBooks: \(error.localizedDescription), Data: \(result.data )")
                throw NetworkError.decodingError(error)
            }
            
            let itemsData = try JSONSerialization.data(withJSONObject: items, options: [])
            let googleBooksResponse = try JSONDecoder().decode([GoogleBookItem].self, from: itemsData)
            return googleBooksResponse
        } catch {
            //print("Error in getBooks: \(error.localizedDescription), SearchTerm: \(searchTerm), Country: \(country)")
            throw NetworkError.decodingError(error)
        }
    }
    
    func getBookByID(bookID: String, country: String) async throws -> GoogleBookItem? {
        do {
            let result = try await functions.httpsCallable("getBookByID").call(["bookID": bookID, "country": country])
            guard let data = result.data as? [String: Any] else {
                let error = NSError(domain: "DecodingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Decoding error in getBookByID"])
                //print("Error in getBookByID: \(error.localizedDescription), Data: \(result.data )")
                throw NetworkError.decodingError(error)
            }

            let dataData = try JSONSerialization.data(withJSONObject: data, options: [])
            let googleBookItem = try JSONDecoder().decode(GoogleBookItem.self, from: dataData)
            return googleBookItem
        } catch {
            //print("Error in getBookByID: \(error.localizedDescription), BookID: \(bookID), Country: \(country)")
            throw NetworkError.decodingError(error)
        }
    }
}

