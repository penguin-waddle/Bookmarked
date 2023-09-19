//
//  StarsSelectionView.swift
//  Bookmarked
//
//  Created by Vivien on 9/15/23.
//

import SwiftUI

struct StarsSelectionView: View {
    @Binding var rating: Int //change to @Binding after layout testing
    @State var interactive = true
    let highestRating = 5
    let unselected = Image(systemName: "star")
    let selected = Image(systemName: "star.fill")
    var font: Font = .largeTitle
    let fillColor: Color = .red
    let emptyColor: Color = .gray
    
    var body: some View {
        HStack {
            ForEach(1...highestRating, id: \.self) { number in
                showStar(for: number)
                    .foregroundColor(number <= rating ? fillColor : emptyColor)
                    .onTapGesture {
                        if interactive {
                            rating = number
                        }
                    }
            }
            .font(font)
        }
    }
    
    func showStar( for number: Int) -> Image {
        if number > rating {
            return unselected
        } else {
            return selected
        }
    }
}

struct StarsSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        StarsSelectionView(rating: .constant(4))
    }
}
