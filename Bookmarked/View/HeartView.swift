//
//  HeartView.swift
//  Bookmarked
//
//  Created by Vivien on 9/29/23.
//
import SwiftUI
import FirebaseAuth

struct HeartView: View {
    @EnvironmentObject var favoritesVM: FavoritesViewModel
    var book: Book
    var fromAPI: Bool
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        Button(action: {
            Task {
                await handleFavoriteToggle()
            }
        }) {
            if favoritesVM.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .red))
                    .scaleEffect(0.5)
            } else {
                Image(systemName: favoritesVM.isFavorite ? "heart.fill" : "heart")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(favoritesVM.isFavorite ? .red : .gray)
                    .frame(width: 30, height: 30)
            }
        }
        .onAppear {
            print("HeartView onAppear called")
            fetchFavoriteStatus()
        }
        .onChange(of: favoritesVM.isFavorite) { newValue in
            print("HeartView observed isFavorite change to: \(newValue)")
        }
        .onChange(of: favoritesVM.isLoading) { _ in
            if let error = favoritesVM.error {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(title: Text("Error"), message: Text(errorMessage ?? "An unknown error occurred"), dismissButton: .default(Text("OK")))
        }
        .onReceive(favoritesVM.objectWillChange, perform: { _ in
            print("HeartView received objectWillChange")
        })
    }

    private func handleFavoriteToggle() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Error: User not logged in."
            showErrorAlert = true
            return
        }
        favoritesVM.toggleFavoriteStatus(userId: userId, book: book)
    }

    private func fetchFavoriteStatus() {
        guard let userId = Auth.auth().currentUser?.uid, let firestoreId = book.firestoreId else {
            print("Error: User not logged in or book ID is unavailable.")
            return
        }
        Task {
            favoritesVM.checkIfBookIsFavorite(userId: userId, firestoreId: firestoreId)
        }
    }
}
















