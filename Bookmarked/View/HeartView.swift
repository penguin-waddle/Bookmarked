//
//  HeartView.swift
//  Bookmarked
//
//  Created by Vivien on 9/29/23.
//
import SwiftUI
import Firebase
import FirebaseFirestore

struct ErrorAlert: Identifiable {
        let id = UUID()
        let message: String
}

struct HeartView: View {
    @Binding var book: Book
    var fromAPI: Bool
    var firestoreService: FirestoreServiceProtocol
    
    @State private var isFavorite: Bool = false
    @State private var favoriteDocID: String? = nil
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var errorAlert: ErrorAlert? = nil
    
    init(book: Binding<Book>, fromAPI: Bool, firestoreService: FirestoreServiceProtocol) {
        _book = book
        self.fromAPI = fromAPI
        self.firestoreService = firestoreService
    }
    
    var body: some View {
        Button(action: toggleFavorite) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .red))
                    .scaleEffect(0.5)
            } else {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(isFavorite ? .red : .gray)
                    .frame(width: 30, height: 30)
            }
            Spacer()
        }
        .disabled(isLoading)
        .onAppear {
            print("HeartView onAppear called")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                print("Book ID in HeartView: \(book.id ?? "Not Available")")
                checkIfBookIsFavorite()
            }
        }
        .alert(item: $errorAlert) { alert in
            Alert(title: Text("Error"), message: Text(alert.message), dismissButton: .default(Text("OK")))
        }
    }
    
    func checkIfBookIsFavorite() {
        print("Checking if book is a favorite...")
        isLoading = true
        let userId = Auth.auth().currentUser!.uid
        
        firestoreService.checkIfBookIsFavorite(userId: userId, book: book, fromAPI: fromAPI) { isFavorite, docId, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorAlert = ErrorAlert(message: "Failed to fetch favorite status: \(error.localizedDescription)")
                    return
                }
                self.isFavorite = isFavorite
                self.favoriteDocID = isFavorite ? docId : nil
            }
        }
    }
    
    func toggleFavorite() {
        isLoading = true
        let userId = Auth.auth().currentUser!.uid
        
        firestoreService.toggleFavoriteStatus(isFavorite: isFavorite, userId: userId, book: book, fromAPI: fromAPI) { success, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorAlert = ErrorAlert(message: "Failed to update favorite status: \(error.localizedDescription)")
                } else {
                    self.isFavorite.toggle()
                }
            }
        }
    }
}


