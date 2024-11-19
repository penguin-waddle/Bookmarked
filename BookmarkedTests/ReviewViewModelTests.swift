//
//  ReviewViewModelTests.swift
//  BookmarkedTests
//
//  Created by Vivien on 11/1/23.
//

import XCTest
@testable import Bookmarked
import Combine

class ReviewViewModelTests: XCTestCase {

    var viewModel: ReviewViewModel!
    var mockService: MockFirestoreService!
    var testBook: Book!
    var testReview: Review!
    var cancellables: Set<AnyCancellable>!

    @MainActor
    override func setUpWithError() throws {
        try super.setUpWithError()
        setUpViewModel()
    }

    @MainActor func setUpViewModel() {
        cancellables = []
        mockService = MockFirestoreService()
        viewModel = ReviewViewModel(firestoreService: mockService)
        testBook = Book(id: "123", title: "Test Book")
        testBook.firestoreId = "123"
        testReview = Review(id: "review123", body: "Nice Book!", rating: 4)
    }

    func testSaveReview() async throws {
        let result = await viewModel.saveReview(book: testBook, review: testReview)
        XCTAssertTrue(result, "Review should be saved successfully")
    }

    func testDeleteReview() async throws {
        let result = await viewModel.deleteReview(book: testBook, review: testReview)
        XCTAssertTrue(result, "Review should be deleted successfully")
    }

    @MainActor func testFetchReviewsForBook() async throws {
        await viewModel.fetchReviews(for: "123")
        XCTAssertEqual(viewModel.reviews.count, 1, "Should have fetched one review.")
        XCTAssertEqual(viewModel.reviews.first?.id, "reviewTest", "Fetched review ID should match.")
    }
}


