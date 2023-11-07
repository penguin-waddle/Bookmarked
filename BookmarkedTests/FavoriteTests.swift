//
//  FavoriteTests.swift
//  BookmarkedTests
//
//  Created by Vivien on 11/1/23.
//

import XCTest
@testable import Bookmarked

class FavoriteTests: XCTestCase {
    
    var mockService: MockFirestoreService!
    var testBook: Book!
    
    override func setUpWithError() throws {
          try super.setUpWithError()
          // Reinitialize the mock service before each test
          mockService = MockFirestoreService()
          // Reset the favorite books before each test
          mockService.favoriteBooks = [:]
          // Setup test book data
          testBook = Book(id: "book123", title: "Test Book", author: "Author", publishedDate: "2021-10-23", imageUrl: nil)
      }

      override func tearDownWithError() throws {
          mockService = nil
          testBook = nil
          try super.tearDownWithError()
      }
    
    func testGetBookId() {
        let bookId = mockService.getBookId(book: testBook, fromAPI: false)
        XCTAssertEqual(bookId, "local_db_id_Test_Book")
    }
    
    func testToggleFavoriteStatus() {
        let addExpectation = expectation(description: "Add to favorites")
        let removeExpectation = expectation(description: "Remove from favorites")

        // First, add to favorites
        mockService.toggleFavoriteStatus(isFavorite: false, userId: "testUserId", book: testBook, fromAPI: false) { success, error in
            XCTAssertTrue(success)
            XCTAssertNil(error)
            addExpectation.fulfill()

            // Inside the completion handler of the first call, initiate the second call
            self.mockService.toggleFavoriteStatus(isFavorite: true, userId: "testUserId", book: self.testBook, fromAPI: false) { success, error in
                XCTAssertTrue(success)
                XCTAssertNil(error)
                removeExpectation.fulfill()
            }
        }

        waitForExpectations(timeout: 5)
    }

    func testCheckIfBookIsFavorite() {
        let userId = "testUserId"
        let bookId = mockService.getBookId(book: testBook, fromAPI: false)
        let documentId = "\(userId)_\(bookId)"
        
        // Manually set the book as favorite before checking
        mockService.favoriteBooks[documentId] = true
        
        let expectation = self.expectation(description: "Check if book is favorite")
        
        mockService.checkIfBookIsFavorite(userId: userId, book: testBook, fromAPI: false) { isFavorite, _, error in
            XCTAssertNil(error)
            XCTAssertTrue(isFavorite)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5)
    }
}
