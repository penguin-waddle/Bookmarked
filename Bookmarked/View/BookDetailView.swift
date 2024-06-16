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
    @State var book: Book
    @ObservedObject var resultsVM: ResultsListViewModel
    @EnvironmentObject var favoritesVM: FavoritesViewModel
    
    var bookID: String
    var activityType: ActivityType
    var fromAPI: Bool = false
    
    @State private var isDescriptionExpanded = false
    @State private var showReviewViewSheet = false
    @State private var showErrorAlert: Bool = false
    var previewRunning = false
    
    var body: some View {
        List {
            Section(header: EmptyView()) {
                HStack(alignment: .top) {
                    Text("") // Empty text for divider to span whole view
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
                        
                        if let pageCount = book.pageCount {
                            Text(pageCount > 0 ? "\(pageCount) pages" : "")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        }
                        
                        if let categories = book.categories {
                            Text(categories.joined(separator: ", "))
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        }
                        
                        if let publishedDate = book.publishedDate {
                            Text("Published \(formatDate(publishedDate))")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.leading, 16)
                }
                .listRowInsets(EdgeInsets())
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
            
            Section {
                ReviewsListView(book: book, handleBookRating: handleBookRating)
            }
            .listRowInsets(EdgeInsets())
        }
        .listStyle(DefaultListStyle())
        .font(.custom("PingFangTC-Regular", size: 16))
        .onAppear {
            print("BookDetailView appeared for bookID: \(bookID), fromAPI: \(fromAPI)")
            Task {
                if fromAPI {
                    await bookVM.fetchBookData(bookID: bookID, firestoreId: nil, fromAPI: true, resultsVM: resultsVM)
                    if let firestoreId = await bookVM.checkAndSetFirestoreIdForBook(book: book) {
                        DispatchQueue.main.async {
                            self.book.firestoreId = firestoreId
                            favoritesVM.checkIfBookIsFavorite(userId: Auth.auth().currentUser!.uid, firestoreId: firestoreId)
                        }
                    } else {
                        DispatchQueue.main.async {
                            favoritesVM.isFavorite = false
                        }
                    }
                } else {
                    await bookVM.fetchBookData(bookID: book.id, firestoreId: book.firestoreId, fromAPI: false)
                    if let firestoreId = book.firestoreId {
                        favoritesVM.checkIfBookIsFavorite(userId: Auth.auth().currentUser!.uid, firestoreId: firestoreId)
                    }
                }
            }
        }
        .onDisappear {
            // Reset view state here
            isDescriptionExpanded = false
            bookVM.resetDataFetchedFlag()
        }
        
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(bookVM.fetchError?.localizedDescription ?? "An unknown error occurred")
        }
        .sheet(isPresented: $showReviewViewSheet) {
            NavigationStack {
                ReviewView(book: book, review: Review())
            }
        }
        .navigationBarItems(trailing: HeartView(book: book, fromAPI: fromAPI))
    }
    
    
    struct ReviewsListView: View {
        let book: Book
        @FirestoreQuery(collectionPath: "") var reviews: [Review]
        var handleBookRating: () -> Void
        
        init(book: Book, handleBookRating: @escaping () -> Void) {
            self.book = book
            self.handleBookRating = handleBookRating
            let bookID = book.firestoreId ?? book.id ?? ""
            _reviews = FirestoreQuery(collectionPath: "books/\(bookID)/reviews")
        }
        
        var averageRating: String {
            guard !reviews.isEmpty else { return "-.-" }
            let totalRating = reviews.reduce(0) { $0 + $1.rating }
            let averageRating = Double(totalRating) / Double(reviews.count)
            return String(format: "%.1f", averageRating)
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Average Rating: \(averageRating)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(action: handleBookRating) {
                        Text("Rate This Book")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                //.padding(.horizontal)
               // .background(Color.gray.opacity(0.1))
                
                ForEach(reviews) { review in
                    NavigationLink(destination: ReviewView(book: book, review: review)) {
                        BookReviewRowView(review: review)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 1)
                    }
                }
            }
            .padding()
        }
    }
    
    
    func handleBookRating() {
        Task {
            if let savedBookId = await bookVM.saveBookIfNotExists(book: book) {
                // Update the book's Firestore ID with the returned value
                DispatchQueue.main.async {
                    self.book.firestoreId = savedBookId
                    self.showReviewViewSheet.toggle()
                    print("Book confirmed saved or found with Firestore ID: \(savedBookId)")
                }
            } else {
                print("Error: Failed to confirm book saved or found.")
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
        // Create dummy data for the preview
        let sampleBook = Book(
            id: "SampleBookID",
            title: "Sample Book Title",
            author: "Sample Author"
            // ... include other necessary properties if needed
        )
        
        let resultsVM = ResultsListViewModel()
        let firestoreService = FirestoreService.shared // Ensure this is initialized correctly for the preview
        
        // Initialize the BookDetailView with the necessary parameters
        BookDetailView (
            book: sampleBook,
            resultsVM: resultsVM,
            bookID: sampleBook.id ?? "",
            activityType: .review,
            fromAPI: false
        )
        .environmentObject(firestoreService) // Provide the environment object if needed
    }
}





