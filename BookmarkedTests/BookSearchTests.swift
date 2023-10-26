//
//  BookSearchTests.swift
//  BookmarkedTests
//
//  Created by Vivien on 10/23/23.
//

import XCTest
@testable import Bookmarked

class BookSearchTests: XCTestCase {

    var mockWebServiceProvider: MockWebServiceProvider!
    var resultsListVM: ResultsListViewModel!
    
    @MainActor override func setUp() {
        super.setUp()
        mockWebServiceProvider = MockWebServiceProvider()
        resultsListVM = ResultsListViewModel(webService: mockWebServiceProvider)
    }

    // 1. Test that searching for a valid term returns expected results
    func testValidSearch() async {
        mockWebServiceProvider.mockBooks = [MockData.sampleBook1, MockData.sampleBook2]
        
        await resultsListVM.search(name: "Harry Potter")
        
        DispatchQueue.main.sync {
            XCTAssertEqual(resultsListVM.books.count, 2)
            XCTAssertEqual(resultsListVM.books.first?.title, "Harry Potter and the Sorcerer's Stone")
        }
    }
    
    // 2. Test that searching for an invalid term returns no results
    func testInvalidSearch() async {
        mockWebServiceProvider.mockBooks = []
        
        await resultsListVM.search(name: "SomeRandomNonExistentBook")
        
        DispatchQueue.main.sync {
            XCTAssertEqual(resultsListVM.books.count, 0)
        }
    }
    
    // 3. Test transformation from GoogleBookItem to ResultsViewModel
    func testResultsViewModelTransformation() {
        let resultVM = ResultsViewModel(googleBookItem: MockData.sampleBook1)
        
        XCTAssertEqual(resultVM.title, "Harry Potter and the Sorcerer's Stone")
        XCTAssertEqual(resultVM.authors, "J.K. Rowling")
        XCTAssertEqual(resultVM.image, "https://example.com/sampleimage.jpg")
    }

}

// Mocking
extension BookSearchTests {
    
    class MockWebServiceProvider: Webservice {
        
        var mockBooks: [GoogleBookItem] = []
        
        override func getBooks(searchTerm: String, country: String) async throws -> [GoogleBookItem] {
            return mockBooks
        }
    }
    
    struct MockData {
        static let sampleBook1 = GoogleBookItem(
            id: "12345",
            volumeInfo: GoogleBookItem.VolumeInfo(
                title: "Harry Potter and the Sorcerer's Stone",
                authors: ["J.K. Rowling"],
                publishedDate: "2000-01-01",
                publisher: "Bloomsbury",
                description: "A book about a young wizard.",
                imageLinks: GoogleBookItem.VolumeInfo.ImageLinks(smallThumbnail: "https://example.com/sampleimage.jpg", thumbnail: "https://example.com/sampleimage.jpg"),
                industryIdentifiers:[GoogleBookItem.VolumeInfo.IndustryIdentifier(type: "ISBN_10", identifier: "1234567890"),
                                     GoogleBookItem.VolumeInfo.IndustryIdentifier(type: "ISBN_13", identifier: "1234567890123")]
            )
        )
        static let sampleBook2 = GoogleBookItem(
            id: "12345",
            volumeInfo: GoogleBookItem.VolumeInfo(
                title: "Harry Potter and the Sorcerer's Stone",
                authors: ["J.K. Rowling"],
                publishedDate: "2000-01-01",
                publisher: "Bloomsbury",
                description: "A book about a young wizard.",
                imageLinks: GoogleBookItem.VolumeInfo.ImageLinks(smallThumbnail: "https://example.com/sampleimage.jpg", thumbnail: "https://example.com/sampleimage.jpg"),
                industryIdentifiers:[GoogleBookItem.VolumeInfo.IndustryIdentifier(type: "ISBN_10", identifier: "1234567890"),
                                     GoogleBookItem.VolumeInfo.IndustryIdentifier(type: "ISBN_13", identifier: "1234567890123")]
            )
        )
    }
}

