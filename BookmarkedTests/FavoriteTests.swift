//
//  FavoriteTests.swift
//  BookmarkedTests
//
//  Created by Vivien on 11/1/23.
//

import XCTest
@testable import Bookmarked
import Combine

class FavoriteTests: XCTestCase {

    var mockService: MockFirestoreService!
    var testBook: Book!
    var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockService = MockFirestoreService()
        cancellables = []
        testBook = Book(id: UUID().uuidString, title: "Test Book")
    }

    func testToggleFavoriteStatus() {
        let expectation = XCTestExpectation(description: "Toggle favorite status should complete")
        
        mockService.toggleFavoriteStatus(userId: "user123", firestoreId: testBook.id!, book: testBook, isFavorite: false)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Failed with error: \(error)")
                }
            }, receiveValue: { isFavorite in
                XCTAssertFalse(isFavorite, "Book should not be favorite initially")

                self.mockService.toggleFavoriteStatus(userId: "user123", firestoreId: self.testBook.id!, book: self.testBook, isFavorite: true)
                    .sink(receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            XCTFail("Failed with error: \(error)")
                        }
                    }, receiveValue: { isFavorite in
                        XCTAssertTrue(isFavorite, "Book should be favorite after toggling")
                        expectation.fulfill()
                    })
                    .store(in: &self.cancellables)
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func testCheckIfBookIsFavorite() {
        let expectation = XCTestExpectation(description: "Check if book is favorite should complete")

        mockService.toggleFavoriteStatus(userId: "user123", firestoreId: testBook.id!, book: testBook, isFavorite: true)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Failed with error: \(error)")
                }
            }, receiveValue: { _ in
                self.mockService.checkIfBookIsFavorite(userId: "user123", firestoreId: self.testBook.id!)
                    .sink(receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            XCTFail("Failed with error: \(error)")
                        }
                    }, receiveValue: { isFavorite in
                        XCTAssertTrue(isFavorite, "Book should be marked as favorite")
                        expectation.fulfill()
                    })
                    .store(in: &self.cancellables)
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }
}

