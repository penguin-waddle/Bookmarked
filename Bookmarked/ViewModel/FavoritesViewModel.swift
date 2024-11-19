//
//  FavoritesViewModel.swift
//  Bookmarked
//
//  Created by Vivien on 1/17/24.
//

import Foundation
import Firebase
import FirebaseFirestore
import Combine

@MainActor
class FavoritesViewModel: ObservableObject {
    private var firestoreService: FirestoreServiceProtocol
    @Published var favorites: [Book] = []
    @Published var isFavorite: Bool = false
    @Published var isLoading: Bool = false
    @Published var error: Error?
    private var cancellables = Set<AnyCancellable>()

    init(firestoreService: FirestoreServiceProtocol = FirestoreService.shared) {
        self.firestoreService = firestoreService
    }

    func checkIfBookIsFavorite(userId: String, firestoreId: String) {
        isLoading = true
        print("Checking favorite status for Firestore ID: \(firestoreId)")
        firestoreService.checkIfBookIsFavorite(userId: userId, firestoreId: firestoreId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        switch completion {
                        case .failure(let error):
                            self?.error = error
                            print("Error checking if book is favorite:", error.localizedDescription)
                        case .finished:
                            break
                        }
                    }
                },
                receiveValue: { [weak self] isFavorite in
                    DispatchQueue.main.async {
                        self?.isFavorite = isFavorite
                        print("Book favorite status:", isFavorite)
                    }
                }
            )
            .store(in: &cancellables)
    }

    func toggleFavoriteStatus(userId: String, book: Book) {
        Task {
            [weak self] in
            guard let self = self else { return }
            
            // Save the book to the "books" collection
            guard let firestoreId = await self.firestoreService.saveBookIfNotExists(book: book) else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.error = NSError(domain: "BookSavingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to save book and cannot toggle favorite status."])
                    print("Failed to save book and cannot toggle favorite status.")
                }
                return
            }
            
            DispatchQueue.main.async {
                self.isLoading = true
                print("Book saved with Firestore ID:", firestoreId)
            }
            
            // Check if the book is already in "favorites"
            self.firestoreService.checkIfBookIsFavorite(userId: userId, firestoreId: firestoreId)
                .receive(on: DispatchQueue.main)
                .flatMap { isFavorite in
                    print("Favorite status before toggle:", isFavorite)
                    if isFavorite {
                        print("Deleting existing favorite document")  // Ensure we don't delete unnecessarily
                        return self.firestoreService.toggleFavoriteStatus(
                            userId: userId,
                            firestoreId: firestoreId,
                            book: book,
                            isFavorite: true  // Correct status for deleting
                        )
                    } else {
                        print("Adding new favorite document")  // Ensure we don't create unnecessarily
                        return self.firestoreService.toggleFavoriteStatus(
                            userId: userId,
                            firestoreId: firestoreId,
                            book: book,
                            isFavorite: false  // Correct status for adding
                        )
                    }
                }
                .handleEvents(receiveOutput: { [weak self] newStatus in
                    self?.updateUserFavorites(userId: userId, firestoreId: firestoreId, isFavorite: newStatus)
                })
                .sink(
                    receiveCompletion: { completion in
                        DispatchQueue.main.async {
                            self.isLoading = false
                            switch completion {
                            case .failure(let error):
                                self.error = error
                                print("Toggle favorite status error:", error)
                            case .finished:
                                print("Toggle favorite status operation completed.")
                            }
                        }
                    },
                    receiveValue: { newStatus in
                        print("Favorite status after toggle:", newStatus)
                        self.isFavorite = newStatus
                    }
                )
                .store(in: &self.cancellables)
        }
    }

    private func updateUserFavorites(userId: String, firestoreId: String, isFavorite: Bool) {
        let userRef = Firestore.firestore().collection("users").document(userId)
        if isFavorite {
            userRef.updateData(["favorites": FieldValue.arrayUnion([firestoreId])])
        } else {
            userRef.updateData(["favorites": FieldValue.arrayRemove([firestoreId])])
        }
    }

    func fetchFavorites(userId: String) async {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        do {
            let books = try await firestoreService.fetchFavorites(userId: userId)
            DispatchQueue.main.async {
                self.favorites = books
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error
                self.isLoading = false
            }
        }
    }

    func resetData() {
        DispatchQueue.main.async {
            self.isFavorite = false
            self.error = nil
            self.isLoading = false
        }
    }
}


