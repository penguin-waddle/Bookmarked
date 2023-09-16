//
//  BookDetailView.swift
//  Bookmarked
//
//  Created by Vivien on 9/14/23.
//

import SwiftUI
import SDWebImageSwiftUI

struct BookDetailView: View {
    var book: Book
    
    @State private var isDescriptionExpanded = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
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

                Divider()
                    .padding(.vertical, 16)

                if let description = book.description {
                    Group {
                        if isDescriptionExpanded || description.split(separator: " ").count <= 50 {
                            Text(description)
                        } else {
                            Text(String(description.prefix(300)) + "...") // Show first 300 characters as an example, adjust as needed
                        }
                    }
                    .padding(.horizontal)
                    
                    if description.split(separator: " ").count > 50 {
                        Button(action: {
                            withAnimation {
                                isDescriptionExpanded.toggle()
                            }
                        }) {
                            Text(isDescriptionExpanded ? "Read Less" : "Read More")
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                    }
                }
                
            }
        }
        .font(.custom("PingFangTC-Regular", size: 16))
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
        BookDetailView(book: Book(title: "Sample Title", author: "Sample Author", description: "This is a sample description for a sample book. The story revolves around ...", publishedDate: "2023", imageUrl: nil))
    }
}


