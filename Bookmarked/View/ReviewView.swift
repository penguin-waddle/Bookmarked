//
//  ReviewView.swift
//  Bookmarked
//
//  Created by Vivien on 9/15/23.
//

import SwiftUI
import Firebase

struct ReviewView: View {
    @State var book: Book
    @State var review: Review
    @State var postedByThisUser = false
    @State private var rateOrReviewerString = "Rate this book:" //otherwise display poster email and date
    @StateObject var reviewVM = ReviewViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            VStack (alignment: .leading) {
                Text(book.title)
                    .font(.title)
                    .bold()
                    .lineLimit(1)

                Text(book.author)
                    .padding(.bottom)
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(rateOrReviewerString)
                .font(postedByThisUser ? .title2 : .subheadline)
                .bold(postedByThisUser)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .padding(.horizontal)
                .padding(.bottom, 5)

            StarsSelectionView(rating: $review.rating)
                .disabled(!postedByThisUser)
                .padding(.bottom)

            VStack (alignment: .leading) {
                Text("Title:")
                    .fontWeight(.semibold)
                
                TextField("Title", text: $review.title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(!postedByThisUser) // disable if not posted by user

                Text("Review:")
                    .fontWeight(.semibold)
                
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $review.body)
                        .frame(minHeight: 100, maxHeight: 200, alignment: .topLeading)
                    if review.body.isEmpty {
                        Text("Review")
                            .foregroundColor(.gray.opacity(0.5))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 8)
                    }
                }
                .disabled(!postedByThisUser)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                        .stroke(.gray.opacity(0.1), lineWidth: postedByThisUser ? 2 : 0.3)
                    )
            }
            .font(.title2)
            .padding(.horizontal)

            Spacer()
        }
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.white,Color.blue.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
                .opacity(0.5)
        )
        .onAppear {
            if review.reviewer == Auth.auth().currentUser?.email {
                postedByThisUser = true
            } else {
                let reviewPostedOn = review.postedOn.formatted(date: .numeric, time: .omitted)
                rateOrReviewerString = "by \(review.reviewer) on: \(reviewPostedOn)"
            }
        }
        .navigationBarBackButtonHidden(postedByThisUser) //hides back button if posted by this user
        .toolbar {
            if postedByThisUser {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            let success = await reviewVM.saveReview(book:book, review: review)
                            if success {
                                dismiss()
                            } else {
                                print("Error saving data in ReviewView!")
                            }
                        }
                    }
                }
                if review.id != nil {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Spacer()
                        Button {
                            Task {
                                let success = await reviewVM.deleteReview(book: book, review: review)
                                if success {
                                    dismiss()
                                }
                            }
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
                
            }
        }
    }
}

struct ReviewView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ReviewView(book: Book(title: "Atomic Habits", author: "James Clear"), review: Review())
        }
    }
}
