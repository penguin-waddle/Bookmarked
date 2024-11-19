//
//  UserViewModel.swift
//  Bookmarked
//
//  Created by Vivien on 1/12/24.
//
import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

@MainActor
class UserViewModel: ObservableObject {
    @Published var user: User? {
        didSet {
            print("User updated: \(String(describing: user))")
        }
    }
    @Published var reviews: [Review] = [] {
        didSet {
            print("Reviews updated: \(reviews)")
        }
    }
    @Published var reviewBooks: [String: Book] = [:] {
        didSet {
            print("Review books updated: \(reviewBooks)")
        }
    }
    @Published var favoritesBooks: [Book] = [] {
        didSet {
            print("Favorites books updated: \(favoritesBooks)")
        }
    }

    private var firestoreService: FirestoreServiceProtocol
    private var reviewsListener: ListenerRegistration?
    private var isFetchingData = false

    init(firestoreService: FirestoreServiceProtocol = FirestoreService.shared) {
        self.firestoreService = firestoreService
    }

    func fetchUserData(userId: String) {
        guard !userId.isEmpty else {
            print("Error: userId is empty")
            return
        }
        guard !isFetchingData else {
            print("Already fetching user data")
            return
        }
        isFetchingData = true

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        print("Fetching user data for userId: \(userId)")

        userRef.getDocument { (document, error) in
            DispatchQueue.main.async {
                if let document = document, document.exists {
                    print("User document fetched successfully")
                    let userData = document.data()
                    print("User data: \(String(describing: userData))")
                    self.user = User(
                        id: userId,
                        name: userData?["name"] as? String ?? "",
                        username: userData?["username"] as? String ?? "",
                        email: userData?["email"] as? String ?? "",
                        password: userData?["password"] as? String ?? "",
                        profilePictureURL: userData?["profilePictureURL"] as? String ?? "",
                        bio: userData?["bio"] as? String ?? "",
                        favorites: userData?["favorites"] as? [String] ?? [],
                        reviews: (userData?["reviews"] as? [[String: Any]])?.compactMap { dict in
                            guard let bookID = dict["bookID"] as? String, let reviewID = dict["reviewID"] as? String else {
                                return nil
                            }
                            return ReviewReference(bookID: bookID, reviewID: reviewID)
                        } ?? [],
                        readLists: userData?["readLists"] as? [String] ?? [],
                        followers: userData?["followers"] as? [String] ?? [],
                        following: userData?["following"] as? [String] ?? []
                    )
                    print("User object created: \(String(describing: self.user))")
                    self.fetchReviewsForUser()
                    self.fetchFavoritesBooks()
                } else {
                    print("Document does not exist")
                }
                self.isFetchingData = false
            }
        }
    }

    func fetchReviewsForUser() { //FOR User-specific cases, not to be confused with reviewVM func
        guard let reviewReferences = user?.reviews, !reviewReferences.isEmpty else {
            print("Error: No review references found")
            return
        }

        let db = Firestore.firestore()

        for reviewReference in reviewReferences {
            let bookID = reviewReference.bookID
            let reviewID = reviewReference.reviewID
            let reviewRef = db.collection("books").document(bookID).collection("reviews").document(reviewID)
            
            print("Fetching review for bookID: \(bookID) reviewID: \(reviewID)")

            reviewRef.getDocument { (reviewDoc, error) in
                if let reviewDoc = reviewDoc, reviewDoc.exists {
                    let review = try? reviewDoc.data(as: Review.self)
                    if let review = review {
                        DispatchQueue.main.async {
                            if !self.reviews.contains(where: { $0.id == review.id }) {
                                self.reviews.append(review)
                                print("Fetched review: \(review)")
                                self.fetchBookForReview(bookID)
                            }
                        }
                    } else {
                        print("Error decoding review: Data is nil")
                    }
                }
            }
        }
    }

    private func fetchBookForReview(_ bookID: String) {
        guard !bookID.isEmpty else {
            print("Error: bookID is empty")
            return
        }
        
        let db = Firestore.firestore()
        let bookRef = db.collection("books").document(bookID)
        
        print("Fetching book for bookID: \(bookID)")

        bookRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let book = try? document.data(as: Book.self)
                if let book = book {
                    DispatchQueue.main.async {
                        self.reviewBooks[bookID] = book
                        print("Fetched book: \(book)")
                        print("Updated reviewBooks: \(self.reviewBooks)")
                    }
                }
            }
        }
    }
    
    func setupReviewsListener(userId: String) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        reviewsListener = userRef.addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot, document.exists else {
                print("Error fetching user data: \(error?.localizedDescription ?? "No error")")
                return
            }
            
            let userData = document.data()
            let reviewReferences: [ReviewReference] = (userData?["reviews"] as? [[String: Any]])?.compactMap { dict in
                guard let bookID = dict["bookID"] as? String, let reviewID = dict["reviewID"] as? String else {
                    return nil
                }
                return ReviewReference(bookID: bookID, reviewID: reviewID)
            } ?? []
            
            self.reviews = []
            for reviewReference in reviewReferences {
                let bookID = reviewReference.bookID
                let reviewID = reviewReference.reviewID
                let reviewRef = db.collection("books").document(bookID).collection("reviews").document(reviewID)
                
                reviewRef.getDocument { (reviewDoc, error) in
                    if let reviewDoc = reviewDoc, reviewDoc.exists {
                        let review = try? reviewDoc.data(as: Review.self)
                        if let review = review {
                            DispatchQueue.main.async {
                                if !self.reviews.contains(where: { $0.id == review.id }) {
                                    self.reviews.append(review)
                                    self.fetchBookForReview(bookID)
                                }
                            }
                        }
                    }
                }
            }
        }
    }


    deinit {
            reviewsListener?.remove()
        }

    func fetchFavoritesBooks() {
        guard let favorites = user?.favorites else { return }
        let db = Firestore.firestore()

        var fetchedBooks: [Book] = []
        let dispatchGroup = DispatchGroup()

        for bookID in favorites {
            dispatchGroup.enter()
            db.collection("books").document(bookID).getDocument { (document, error) in
                if let document = document, document.exists {
                    let book = try? document.data(as: Book.self)
                    if let book = book {
                        fetchedBooks.append(book)
                    }
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            self.favoritesBooks = fetchedBooks
            print("Fetched favorite books: \(self.favoritesBooks)")
        }
    }
    
    func uploadProfilePicture(_ image: UIImage, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let storageRef = Storage.storage().reference().child("profile_pictures/\(userId).jpg")
        guard let imageData = image.jpegData(compressionQuality: 0.75) else { return }
        
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url))
                }
            }
        }
    }
    
    func updateUserData(selectedImage: UIImage?) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        var updates: [String: Any] = [
            "name": user?.name ?? "",
            "username": user?.username ?? "",
            "bio": user?.bio ?? ""
        ]
        
        if let selectedImage = selectedImage {
            uploadProfilePicture(selectedImage) { result in
                switch result {
                case .success(let url):
                    updates["profilePictureURL"] = url.absoluteString
                    self.updateUserProfile(userId: userId, updates: updates)
                case .failure(let error):
                    print("Error uploading profile picture: \(error.localizedDescription)")
                }
            }
        } else {
            updateUserProfile(userId: userId, updates: updates)
        }
    }
    
    private func updateUserProfile(userId: String, updates: [String: Any]) {
        Firestore.firestore().collection("users").document(userId).updateData(updates) { error in
            if let error = error {
                print("Error updating user profile: \(error.localizedDescription)")
            } else {
                print("User profile successfully updated.")
                self.fetchUserData(userId: userId) // Refresh the user data
            }
        }
    }
}














