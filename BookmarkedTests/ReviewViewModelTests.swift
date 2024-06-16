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
        let expectation = XCTestExpectation(description: "Save review should complete")

        do {
            let result = try await viewModel.saveReview(book: testBook, review: testReview)
            XCTAssertTrue(result, "Review should be saved successfully")
            expectation.fulfill()
        } catch {
            XCTFail("Save review failed with error: \(error)")
        }

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testDeleteReview() async throws {
        let expectation = XCTestExpectation(description: "Delete review should complete")

        do {
            let result = try await viewModel.deleteReview(book: testBook, review: testReview)
            XCTAssertTrue(result, "Review should be deleted successfully")
            expectation.fulfill()
        } catch {
            XCTFail("Delete review failed with error: \(error)")
        }

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testFetchReviewsForBook() async throws {
        let expectation = XCTestExpectation(description: "Fetch reviews should complete")

        do {
            await viewModel.fetchReviews(for: "123")

            XCTAssertEqual(viewModel.reviews.count, 1, "Should have fetched one review.")
            XCTAssertEqual(viewModel.reviews.first?.id, "reviewTest", "Fetched review ID should match.")
            expectation.fulfill()
        } catch {
            XCTFail("Fetch reviews failed with error: \(error)")
        }

        await fulfillment(of: [expectation], timeout: 1.0)
    }
}
