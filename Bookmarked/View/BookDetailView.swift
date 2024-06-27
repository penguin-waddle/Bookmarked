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
    @ObservedObject var bookVM: BookViewModel
    @ObservedObject var resultsVM: ResultsListViewModel
    @EnvironmentObject var favoritesVM: FavoritesViewModel
    @EnvironmentObject var reviewVM: ReviewViewModel

    @State var book: Book
    var bookID: String
    var activityType: ActivityType
    var fromAPI: Bool
    var fromListView: Bool

    @State private var isDescriptionExpanded = false
    @State private var showReviewViewSheet = false
    @State private var showErrorAlert: Bool = false
    var previewRunning = false

    var body: some View {
        List {
            Section(header: EmptyView()) {
                HStack(alignment: .top) {
                    Text("") // Empty text for divider to span whole view
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
                            Text(String(description.prefix(300)) + "...")
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
        .padding(.top, -5)
        .listStyle(DefaultListStyle())
        .font(.custom("PingFangTC-Regular", size: 16))
        .onAppear {
            print("BookDetailView appeared for bookID: \(bookID), fromAPI: \(fromAPI)")
            reviewVM.resetData()
            Task {
                if fromAPI {
                    print("Fetching data from API")
                    await bookVM.fetchBookData(bookID: bookID, firestoreId: nil, fromAPI: true, resultsVM: resultsVM)
                    if let firestoreId = await bookVM.checkAndSetFirestoreIdForBook(book: book) {
                        DispatchQueue.main.async {
                            self.book.firestoreId = firestoreId
                            print("Book firestoreId set: \(firestoreId)")
                            favoritesVM.checkIfBookIsFavorite(userId: Auth.auth().currentUser!.uid, firestoreId: firestoreId)
                        }
                        await reviewVM.fetchReviews(for: firestoreId)
                    } else {
                        DispatchQueue.main.async {
                            favoritesVM.isFavorite = false
                        }
                    }
                } else {
                    if fromListView {
                        print("Fetching data from ListView")
                        await bookVM.fetchBookData(bookID: bookID, firestoreId: bookID, fromAPI: false)
                        favoritesVM.checkIfBookIsFavorite(userId: Auth.auth().currentUser!.uid, firestoreId: bookID)
                        await reviewVM.fetchReviews(for: bookID)
                    } else {
                        print("Fetching data normally")
                        await bookVM.fetchBookData(bookID: book.id, firestoreId: book.firestoreId, fromAPI: false)
                        if let firestoreId = book.firestoreId {
                            favoritesVM.checkIfBookIsFavorite(userId: Auth.auth().currentUser!.uid, firestoreId: firestoreId)
                            await reviewVM.fetchReviews(for: firestoreId)
                        }
                    }
                }
            }
        }
        .onDisappear {
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
        @EnvironmentObject var reviewVM: ReviewViewModel
        var handleBookRating: () -> Void
        
        var averageRating: String {
            guard !reviewVM.reviews.isEmpty else { return "-.-" }
            let totalRating = reviewVM.reviews.reduce(0) { $0 + $1.rating }
            let averageRating = Double(totalRating) / Double(reviewVM.reviews.count)
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
                    .buttonStyle(BorderlessButtonStyle())
                }
                
                ForEach(reviewVM.reviews, id: \.self) { review in
                    BookReviewRowView(review: review)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 1)
                }
            }
            .padding()
            .onAppear {
                print("ReviewsListView appeared for book with ID: \(book.firestoreId ?? "nil")")
            }
        }
    }
    
    func handleBookRating() {
        Task {
            if let savedBookId = await bookVM.saveBookIfNotExists(book: book) {
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
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        if let date = inputFormatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "MMMM dd, yyyy"
            return outputFormatter.string(from: date)
        } else {
            return dateString
        }
    }
}


struct BookDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleBook = Book(
            id: "SampleBookID",
            title: "Sample Book Title",
            author: "Sample Author"
        )
        
        let resultsVM = ResultsListViewModel()
        let firestoreService = FirestoreService.shared
        
        BookDetailView (
            bookVM: BookViewModel(),
            resultsVM: resultsVM,
            book: sampleBook,
            bookID: "1234",
            activityType: .review,
            fromAPI: false,
            fromListView: true
        )
        .environmentObject(firestoreService)
    }
}





