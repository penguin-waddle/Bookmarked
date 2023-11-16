//
//  BookDetailView.swift
//  Bookmarked
//
//  Created by Vivien on 9/14/23.
//

import SwiftUI
import SDWebImageSwiftUI
import FirebaseFirestoreSwift
import FirebaseFirestore
import FirebaseAuth

struct BookDetailView: View {
    @EnvironmentObject var bookVM: BookViewModel
    @EnvironmentObject var firestoreService: FirestoreService
    @State private var book: Book = Book()
    @ObservedObject var resultsVM: ResultsListViewModel

    var bookID: String
    var activityType: ActivityType
    var fromAPI: Bool = false
    
    @FirestoreQuery(collectionPath: "invalid_path") var reviews: [Review]
    @State private var isDescriptionExpanded = false
    @State private var showReviewViewSheet = false
    var previewRunning = false
    var avgRating: String {
        guard reviews.count != 0 else {
            return "-.-"
        }
        let averageValue = Double(reviews.reduce(0) {$0 + $1.rating}) / Double(reviews.count)
        return String(format: "%.1f", averageValue)
    }

    var body: some View {
        List {
            Section(header: EmptyView()) {
                HStack(alignment: .top) {
                    // Display the cover image if the imageUrl is available
                    if let imageUrl = book.imageUrl, let url = URL(string: imageUrl) {
                        WebImage(url: url)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100)
                            .cornerRadius(10)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(book.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("By \(book.author)")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        if let publishedDate = book.publishedDate {
                            Text("Published on \(formatDate(publishedDate))")
                                .font(.callout)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.leading, 16)
                }
                .padding()

                if let description = book.description {
                    Group {
                        if isDescriptionExpanded || description.split(separator: " ").count <= 50 {
                            Text(description)
                        } else {
                            Text(String(description.prefix(300)) + "...") // Show first 300 characters as an example
                        }
                    }
                    
                    if description.split(separator: " ").count > 50 {
                        Button(action: {
                            withAnimation {
                                isDescriptionExpanded.toggle()
                            }
                        }) {
                            Text(isDescriptionExpanded ? "Read Less" : "Read More")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }

            Section(header:
                HStack {
                    Text("Avg. Rating:")
                        .font(.title2)
                        .bold()
                    Text(avgRating)
                        .font(.title)
                        .fontWeight(.black)
                        .foregroundColor(Color("BookColor"))
                    Spacer()
                    Button("Rate this book") {
                        handleBookRating()
                    }
                    .buttonStyle(.borderedProminent)
                    .bold()
                    .tint(Color("BookColor"))
                }
            ) {
                ForEach(reviews) { review in
                    NavigationLink {
                        ReviewView(book: book, review: review)
                    } label: {
                        BookReviewRowView(review: review)
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
        .font(.custom("PingFangTC-Regular", size: 16))
        .onAppear {
            guard !bookID.isEmpty else {
                print("Error: Invalid Book ID")
                print("Book ID in BookDetailView: \(book.id ?? "Not Available")")
                return // Exit if the book ID isn't valid
            }

            $reviews.path = "books/\(bookID)/reviews"

            if fromAPI {
                // Fetch data from Google Books API
                if let resultViewModel = resultsVM.books.first(where: { $0.id == bookID }) {
                    self.book = resultViewModel.book
                }
            } else {
                book = bookVM.book
                var docRef: DocumentReference!
                
                switch activityType {
                case .review:
                    // Fetch from the books collection using the bookID
                    docRef = Firestore.firestore().collection("books").document(bookID)
                case .favorite:
                    // Fetch from the favorites collection using a combined ID of userID and bookID.
                    let userId = Auth.auth().currentUser!.uid
                    let documentId = "\(userId)_\(bookID)"
                    docRef = Firestore.firestore().collection("favorites").document(documentId)
                }
                
                docRef.getDocument { (document, error) in
                                      if let document = document {
                                          if document.exists {
                                              if let fetchedBook = try? document.data(as: Book.self) {
                                                  self.book = fetchedBook
                                              } else {
                                                  print("Failed to decode book from document data.")
                                              }
                                          } else {
                                              print("Document does not exist at path: \(docRef.path)")
                                          }
                                      } else {
                                          print("Book not found or error fetching book: \(error?.localizedDescription ?? "No error")")
                                      }
                                  }
                           }
        }
        .sheet(isPresented: $showReviewViewSheet) {
            NavigationStack {
                ReviewView(book: book, review: Review())
            }
        }
        .navigationBarItems(trailing: HeartView(book: $book, fromAPI: fromAPI, firestoreService: firestoreService))
    }
    
    func handleBookRating() {
            Task {
                let success = await bookVM.saveBookIfNotExists(book: book)
                if success {
                    print("Book saved!")
                    showReviewViewSheet.toggle()
                } else {
                    print("Error saving the book!")
                }
            }
        }
    
    func formatDate(_ dateString: String) -> String {
           // Create a date formatter to parse the date string
           let inputFormatter = DateFormatter()
           inputFormatter.dateFormat = "yyyy-MM-dd" // Assuming the original format is this

           // Check if we can create a Date object from the string
           if let date = inputFormatter.date(from: dateString) {
               // Format the date object to the desired format
               let outputFormatter = DateFormatter()
               outputFormatter.dateFormat = "MMMM dd, yyyy"
               return outputFormatter.string(from: date)
           } else {
               // If we cannot create a Date object, return the original string
               return dateString
           }
       }
}

struct BookDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let firestoreService = FirestoreService()
        
        return BookDetailView(resultsVM: ResultsListViewModel(), bookID: "SampleBookID", activityType: .review, fromAPI: false, previewRunning: true)
            .environmentObject(firestoreService)
    }
}





