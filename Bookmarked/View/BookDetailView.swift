//
//  BookDetailView.swift
//  Bookmarked
//
//  Created by Vivien on 8/23/23.
//

import SwiftUI

struct BookDetailView: View {
    @EnvironmentObject var bookVM: BookViewModel
    @State var book: Book
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            Group {
                TextField("Title", text: $book.title)
                    .font(.title)
                TextField("Author", text: $book.author)
                    .font(.title2)
            }
            .disabled(book.id == nil ? false : true)
            .textFieldStyle(.roundedBorder)
            .overlay {
                RoundedRectangle(cornerRadius: 5)
                    .stroke(.gray.opacity(0.5), lineWidth: book.id == nil ? 2 : 0)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(book.id == nil)
        .toolbar {
            if book.id == nil {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            let success = await bookVM.saveBook(book: book)
                            if success {
                                dismiss()
                            } else {
                                print("Error saving book!")
                            }
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}

struct BookDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            BookDetailView(book: Book())
                .environmentObject(BookViewModel())
        }
    }
}
