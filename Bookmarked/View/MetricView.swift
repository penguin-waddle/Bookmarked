//
//  MetricView.swift
//  Bookmarked
//
//  Created by Vivien on 1/15/24.
//

import SwiftUI

struct MetricView: View {
    var title: String
    var value: String

    var body: some View {
        VStack {
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    MetricView(title: "Reviews", value: "57")
                .previewLayout(.sizeThatFits)
                .padding()
}
