//
//  ReviewViewModelTests.swift
//  BookmarkedTests
//
//  Created by Vivien on 11/1/23.
//

import XCTest
@testable import Bookmarked

class ReviewViewModelTests: XCTestCase {
    
    var viewModel: ReviewViewModel!
    var mockService: MockFirestoreService!
    var testBook: Book!
    var testReview: Review!

    override func setUpWithError() throws {
        try super.setUpWithError()
        // Initialize the mock service
        mockService = MockFirestoreService()
        // Initialize the view model with the mock service
        viewModel = ReviewViewModel(service: mockService)
        // Setup the test data
        testBook = Book(id: "book123", title: "Test Book", author: "Author", description: nil, publishedDate: "2021-10-23", imageUrl: nil)
        testReview = Review(id: "review123", title: "Test Review", body: "Nice Book!", rating: 4, reviewer: "user@example.com", postedOn: Date(), userID: "user123", bookID: "book123")
    }

    override func tearDownWithError() throws {
        // Deallocate and clean up
        viewModel = nil
        mockService = nil
        testBook = nil
        testReview = nil
        try super.tearDownWithError()
    }

    func testSaveReview() async throws {
        let success = await viewModel.saveReview(book: testBook, review: testReview)
        XCTAssertTrue(success)
        // Check if the review was saved correctly in the mock service
    }

    func testDeleteReview() async throws {
        // Ensure a clean state for the review
        mockService.reviews.removeAll()
        
        let saveSuccess = await viewModel.saveReview(book: testBook, review: testReview)
        XCTAssertTrue(saveSuccess)

        let deleteSuccess = await viewModel.deleteReview(book: testBook, review: testReview)
        XCTAssertTrue(deleteSuccess)
        // Check if the review was deleted correctly in the mock service
    }
}
