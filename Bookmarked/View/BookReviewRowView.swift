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
        VStack(alignment: .leading) {
            Text(review.title)
                .font(.title2)
            HStack {
                StarsSelectionView(rating: $review.rating, interactive: false, font: .callout)
                Text(review.body)
                    .font(.callout)
                    .lineLimit(1)
            }
        }
    }
}

#Preview {
    BookReviewRowView(review: Review(title: "Great book!", body: "Made me cry, lots of emotional moments. Only critique are the plot holes.", rating: 4))
}
