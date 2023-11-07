//
//  ReviewViewModel.swift
//  Bookmarked
//
//  Created by Vivien on 9/18/23.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class ReviewViewModel: ObservableObject {
    private var firestoreService: FirestoreServiceProtocol
        
    init(service: FirestoreServiceProtocol = FirestoreService()) {
        self.firestoreService = service
    }
    
    @Published var review = Review()
    
    func saveReview(book: Book, review: Review) async -> Bool {
        return await firestoreService.saveReview(for: book, review: review)
    }
    
    func deleteReview(book: Book, review: Review) async -> Bool {
        return await firestoreService.deleteReview(for: book, review: review)
    }
}
