//
//  BookReviewRowView.swift
//  Bookmarked
//
//  Created by Vivien on 9/18/23.
//

import SwiftUI

struct BookReviewRowView: View {
    @State var review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(review.title)
                .font(.title3)
                .fontWeight(.light)
            HStack {
                StarsSelectionView(rating: $review.rating, interactive: false, font: .callout)
                Spacer(minLength: 8)
                Text(review.body)
                    .font(.callout)
                    .lineLimit(1)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    BookReviewRowView(review: Review(title: "Great book!", body: "Made me cry, lots of emotional moments. Only critique are the plot holes.", rating: 4))
}
