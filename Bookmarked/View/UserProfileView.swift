//
//  UserProfileView.swift
//  Bookmarked
//
//  Created by Vivien on 1/15/24.
//
import FirebaseFirestore
import FirebaseAuth
import SwiftUI
import SDWebImageSwiftUI
import SlidingTabView
import PhotosUI

struct UserReviewsListView: View {
    @EnvironmentObject var userVM: UserViewModel
    @EnvironmentObject var reviewVM: ReviewViewModel
    
    @Binding var isEditing: Bool
    @State private var selectedReview: Review?
    @State private var selectedBook: Book?
    @State private var showingReviewSheet = false
    @State private var showBookDetail = false
    
    var onDelete: (Review) -> Void
    
    var body: some View {
        NavigationStack {
            VStack {
                List(userVM.reviews, id: \.id) { review in
                    if let bookID = review.bookID, let book = userVM.reviewBooks[bookID] {
                        NavigationLink(destination: BookDetailView(book: book)) {
                            UserReviewWithBookView(
                                bookID: bookID,
                                book: book,
                                review: review,
                                isEditing: isEditing,
                                onEdit: {
                                    selectedReview = review
                                    selectedBook = book
                                    if selectedReview != nil && selectedBook != nil {
                                        showingReviewSheet = true
                                    }
                                },
                                onDelete: {
                                    onDelete(review)
                                }
                            )
                        }
                        .environmentObject(userVM)
                        .environmentObject(reviewVM)
                    } else {
                        Text("No reviews yet!")
                    }
                }
            }
            .sheet(isPresented: Binding(
                get: { selectedReview != nil && selectedBook != nil && showingReviewSheet },
                set: { showing in
                    showingReviewSheet = showing
                    if !showing {
                        selectedReview = nil
                        selectedBook = nil
                    }
                }
            ), onDismiss: {
                showingReviewSheet = false
                userVM.setupReviewsListener(userId: Auth.auth().currentUser!.uid)
            }) {
                if let selectedBook = selectedBook, let selectedReview = selectedReview {
                    NavigationStack {
                        ReviewView(book: selectedBook, review: selectedReview, context: .userProfile)
                    }
                }
            }
        }
    }
}



struct UserProfileView: View {
    @EnvironmentObject var userVM: UserViewModel
    @EnvironmentObject var reviewVM: ReviewViewModel
    @State private var tabIndex = 0
    @State private var isEditing = false
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var usernameAvailable: Bool? = nil
    @State private var originalUsername: String?
    @State private var reviewToDelete: Review?
    
    @State private var activeAlert: ActiveAlert?

    enum ActiveAlert: Identifiable {
        case deleteReview
        case deleteError
        case usernameError(String)
        
        var id: String {
            switch self {
            case .deleteReview:
                return "deleteReview"
            case .deleteError:
                return "deleteError"
            case .usernameError(let message):
                return message
            }
        }
    }

    private var nameBinding: Binding<String> {
        Binding(
            get: { userVM.user?.name ?? "" },
            set: { newValue in userVM.user?.name = newValue }
        )
    }

    private var usernameBinding: Binding<String> {
        Binding(
            get: { userVM.user?.username ?? "" },
            set: { newValue in
                let filteredValue = newValue.replacingOccurrences(of: " ", with: "")
                userVM.user?.username = filteredValue
                if filteredValue == originalUsername {
                    usernameAvailable = true
                } else {
                    if filteredValue.isEmpty {
                        usernameAvailable = nil
                    } else {
                        checkUsernameAvailability(filteredValue)
                    }
                }
            }
        )
    }

    private var bioBinding: Binding<String> {
        Binding(
            get: { userVM.user?.bio ?? "" },
            set: { newValue in userVM.user?.bio = newValue }
        )
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .center, spacing: 15) {
                profilePictureView
                userInfoView
                metricsView
                tabsView
            }
            .padding(.top, 10)
            .onAppear {
                fetchUserData()
                originalUsername = userVM.user?.username
                
                if let userId = Auth.auth().currentUser?.uid {
                    userVM.setupReviewsListener(userId: userId)
                }
            }
            .onChange(of: userVM.reviews) { _ in print("UserProfileView detected reviews update: \(userVM.reviews)") }
            .onChange(of: userVM.favoritesBooks) { _ in print("UserProfileView detected favorites update: \(userVM.favoritesBooks)") }
            .navigationBarItems(trailing: editButton)
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .alert(item: $activeAlert) { alert in
                switch alert {
                case .deleteReview:
                    return Alert(
                        title: Text("Delete Review"),
                        message: Text("Are you sure you want to delete this review?"),
                        primaryButton: .destructive(Text("Delete")) {
                            if let reviewToDelete = reviewToDelete, let book = userVM.reviewBooks[reviewToDelete.bookID ?? ""] {
                                Task {
                                    let success = await reviewVM.deleteReview(book: book, review: reviewToDelete)
                                    if success {
                                        userVM.reviews.removeAll { $0.id == reviewToDelete.id }
                                    } else {
                                        activeAlert = .deleteError
                                    }
                                }
                            }
                        },
                        secondaryButton: .cancel()
                    )
                case .deleteError:
                    return Alert(
                        title: Text("Error"),
                        message: Text("Failed to delete the review. Please try again."),
                        dismissButton: .default(Text("OK"))
                    )
                case .usernameError(let message):
                    return Alert(
                        title: Text("Error"),
                        message: Text(message),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
        }
    }

    private var profilePictureView: some View {
        ZStack {
            if let profilePictureURL = userVM.user?.profilePictureURL, let url = URL(string: profilePictureURL), selectedImage == nil {
                WebImage(url: url)
                    .resizable()
                    .placeholder {
                        Circle().fill(Color.gray.opacity(0.3)).overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                                .font(.system(size: 75))
                        )
                        .frame(width: 150, height: 150)
                    }
                    .indicator(.activity)
                    .transition(.fade(duration: 0.5))
                    .scaledToFill()
                    .frame(width: 150, height: 150)
                    .clipShape(Circle())
            } else if let selectedImage = selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 150, height: 150)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 75))
                    )
                    .frame(width: 150, height: 150)
            }

            if isEditing {
                Circle()
                    .strokeBorder(Color.black.opacity(0.5), lineWidth: 1)
                    .background(Circle().foregroundColor(Color.black.opacity(0.5)))
                    .frame(width: 150, height: 150)
                    .overlay(
                        Image(systemName: "pencil")
                            .foregroundColor(.white)
                            .font(.system(size: 25))
                    )
                    .onTapGesture {
                        showingImagePicker = true
                    }
            }
        }
    }

    private var userInfoView: some View {
        VStack(spacing: 5) {
            if let user = userVM.user {
                if isEditing {
                    VStack(spacing: 8) {
                        EditableTextField(text: nameBinding, placeholder: "Name", isEditing: $isEditing)
                        ZStack(alignment: .trailing) {
                            EditableTextField(text: usernameBinding, placeholder: "Username", isEditing: $isEditing)
                            if let available = usernameAvailable {
                                Image(systemName: available ? "checkmark.circle" : "xmark.circle")
                                    .foregroundColor(available ? .green : .red)
                                    .padding(.trailing, 30)
                                    .padding(.bottom, 30)
                            }
                        }
                        EditableTextField(text: bioBinding, placeholder: "Bio", isEditing: $isEditing, isBio: true)
                    }
                    .padding(.horizontal, 15)
                    .cornerRadius(10)
                    .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                } else {
                    Text(user.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    Text("@\(user.username)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    Text(user.bio)
                        .font(.body)
                        .multilineTextAlignment(.center)
                }
            } else {
                Text("Loading...")
            }
        }
    }


    private var metricsView: some View {
        HStack(spacing: 100) {
            MetricView(title: "Followers", value: "\(userVM.user?.followers.count ?? 0)")
            MetricView(title: "Following", value: "\(userVM.user?.following.count ?? 0)")
        }
    }

    private var tabsView: some View {
        VStack {
            SlidingTabView(
                selection: $tabIndex,
                tabs: [
                    "Reviews (\(userVM.user?.reviews.count ?? 0))",
                    "Favorites (\(userVM.user?.favorites.count ?? 0))"
                ],
                animation: .easeInOut
            )

            if tabIndex == 0 {
                UserReviewsListView(isEditing: $isEditing) { review in
                    reviewToDelete = review
                    activeAlert = .deleteReview
                }
                .environmentObject(userVM)
            } else if tabIndex == 1 {
                BookShelfView(books: userVM.favoritesBooks).environmentObject(userVM)
            }
        }
    }

    private var editButton: some View {
        Button(action: {
            if isEditing {
                // Check the availability of the username before proceeding
                if usernameAvailable == false {
                    activeAlert = .usernameError("Username is unavailable. Please choose a different one.")
                } else if nameBinding.wrappedValue.isEmpty || usernameBinding.wrappedValue.isEmpty {
                    activeAlert = .usernameError("Name and username cannot be empty.")
                } else {
                    userVM.updateUserData(selectedImage: selectedImage)
                    if usernameBinding.wrappedValue == originalUsername {
                        usernameAvailable = true
                    }
                    isEditing.toggle()
                }
            } else {
                originalUsername = userVM.user?.username
                isEditing.toggle()
            }
        }) {
            Text(isEditing ? "Done" : "Edit")
        }
    }

    private func fetchUserData() {
        if let userId = Auth.auth().currentUser?.uid, !userId.isEmpty {
            print("Fetching user data for userId: \(userId)")
            userVM.fetchUserData(userId: userId)
        } else {
            print("Error: userId is empty or nil")
        }
    }

    private func checkUsernameAvailability(_ username: String) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").whereField("username", isEqualTo: username)
        userRef.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error checking username: \(error.localizedDescription)")
                usernameAvailable = false
            } else if let querySnapshot = querySnapshot, !querySnapshot.isEmpty {
                usernameAvailable = false
            } else {
                usernameAvailable = true
            }
        }
    }
}

struct EditableTextField: View {
    @Binding var text: String
    var placeholder: String
    @Binding var isEditing: Bool
    var isBio: Bool = false
    var characterLimit: Int = 160

    var body: some View {
        HStack {
            GeometryReader { geometry in
                ZStack(alignment: .trailing) {
                    TextField(placeholder, text: $text, onEditingChanged: { editing in
                        if editing {
                            isEditing = true
                        }
                    })
                    .font(isBio ? .body : .title2)
                    .foregroundColor(isBio ? .primary : .gray)
                    .multilineTextAlignment(.center)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(.leading, 10)  // Add padding to the left
                    .background(Color.white)
                    .cornerRadius(8)
                    .disabled(!isEditing)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray, lineWidth: 1)
                    )

                    if isEditing {
                        HStack(spacing: 5) {
                            if isBio {
                                Text("\(text.count)/\(characterLimit)")
                                    .font(.caption)
                                    .foregroundColor(text.count > characterLimit ? .red : .gray)
                                    .padding(.trailing, 10)
                            }
                            Button(action: {
                                // editing mode
                                isEditing = true
                            }) {
                                Image(systemName: "pencil")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 5)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, isBio ? 35 : 60)  // Adjust padding
    }
}

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        let userVM = UserViewModel(firestoreService: FirestoreService.shared)
        let reviewVM = ReviewViewModel(firestoreService: FirestoreService.shared)

        userVM.user = User(
            id: "1234",
            name: "Vivien",
            username: "vivreads",
            email: "vivien@gmail.com",
            password: "",
            profilePictureURL: "",
            bio: "hello this is bio",
            favorites: ["nil"],
            reviews: [ReviewReference(bookID: "2323", reviewID: "56576")],
            readLists: ["nil"],
            followers: ["nil"],
            following: ["nil"]
        )

        userVM.reviews = [
            Review(
                id: "56576",
                title: "Test Review",
                body: "Great book!",
                rating: 5,
                reviewer: "vivien@gmail.com",
                postedOn: Date(),
                userId: "1234",
                bookID: "2323"
            )
        ]

        userVM.reviewBooks = [
            "2323": Book(
                id: "2323",
                title: "Sample Book",
                author: "Author Name",
                description: "Sample description",
                publishedDate: "2021-03-16",
                publisher: "Publisher Name",
                isbn10: "1234567890",
                isbn13: "1234567890123",
                imageUrl: "http://example.com/image.jpg",
                pageCount: 100,
                categories: ["Fiction"]
            )
        ]
        
        return UserProfileView()
            .environmentObject(userVM)
            .environmentObject(reviewVM)
    }
}


















