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
    
    @State private var isFavorite: Bool = false
    @State private var favoriteDocID: String? = nil
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var errorAlert: ErrorAlert? = nil

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
        
        let bookId: String
        if fromAPI {
            bookId = book.id ?? ""
        } else {
            if let range = book.id?.range(of: "_") {
                bookId = String(book.id?[range.upperBound...] ?? "")
            } else {
                bookId = ""
            }
        }
        
        let documentId = "\(userId)_\(bookId)"
        print("Document ID being checked: \(documentId)")

        let favoriteDocument = Firestore.firestore().collection("favorites").document(documentId)
            
        favoriteDocument.getDocument { (documentSnapshot, error) in
            DispatchQueue.main.async {
                self.isLoading = false
                    
                if let error = error {
                    self.errorAlert = ErrorAlert(message: "Failed to fetch favorite status: \(error.localizedDescription)")
                    return
                }

                if let document = documentSnapshot, document.exists {
                    self.isFavorite = true
                    self.favoriteDocID = documentId
                } else {
                    self.isFavorite = false
                    self.favoriteDocID = nil
                }
            }
        }
    }

    func toggleFavorite() {
        isLoading = true

        // Combine the userID and bookID to create a unique document ID
        let userId = Auth.auth().currentUser!.uid
        
        let bookId: String
        if fromAPI {
            bookId = book.id ?? ""
        } else {
            if let range = book.id?.range(of: "_") {
                bookId = String(book.id?[range.upperBound...] ?? "")
            } else {
                bookId = ""
            }
        }
        
        let documentId = "\(userId)_\(bookId)"

        if isFavorite {
            Firestore.firestore().collection("favorites").document(documentId).delete() { error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let error = error {
                        self.errorMessage = "Failed to remove favorite: \(error.localizedDescription)"
                    } else {
                        self.isFavorite = false
                    }
                }
            }
        } else {
            let favoriteData: [String: Any] = [
                        "userID": userId,
                        "bookID": book.id ?? "",
                        "title": book.title,
                        "author": book.author,
                        "imageUrl": book.imageUrl ?? "",
                        "description": book.description ?? "",
                        "publishedDate": book.publishedDate ?? "",
                        "publisher": book.publisher ?? ""
            ]
            Firestore.firestore().collection("favorites").document(documentId).setData(favoriteData) { error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let error = error {
                        self.errorAlert = ErrorAlert(message: "Failed to add favorite: \(error.localizedDescription)")
                    } else {
                        self.isFavorite = true
                    }
                }
            }
        }
    }
}

