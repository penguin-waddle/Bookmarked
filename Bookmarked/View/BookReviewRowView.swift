//
//  BookReviewRowView.swift
//  Bookmarked
//
//  Created by Vivien on 9/18/23.
//
import SwiftUI
import ExpandableText

struct BookReviewRowView: View {
    @State var review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(review.title)
                .font(.title3)
                .fontWeight(.light)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            StarsSelectionView(rating: $review.rating, interactive: false, font: .callout)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ExpandableText(text: review.body)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(3)
                .expandButton(TextSet(text: "more", font: .body, color: .blue))
                .collapseButton(TextSet(text: "less", font: .body, color: .blue))
                .expandAnimation(.easeOut)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(BorderlessButtonStyle())
        .frame(maxWidth: .infinity)
        .padding()
        .padding(.vertical, 4)
    }
}

#Preview {
    BookReviewRowView(review: Review(title: "Great book!", body: "Made me cry, lots of emotional moments. Only critique are the plot holes.", rating: 4))
}

