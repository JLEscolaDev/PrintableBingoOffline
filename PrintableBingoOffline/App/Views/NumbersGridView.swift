//
//  NumbersGridView.swift
//  PrintableBingoOffline
//
//  Created by Jose Luis Escolá García on 28/12/24.
//

import SwiftUI

struct NumbersGridView: View {
    let allNumbers: [Int]
    let drawnNumbers: [Int]
    var compact: Bool = false

    var body: some View {
        GeometryReader { geometry in
            let spacing: CGFloat = compact ? 6 : 10
            let padding: CGFloat = compact ? 10 : 20
            let availableWidth = max(0, geometry.size.width - padding * 2)
            let availableHeight = max(0, geometry.size.height - padding * 2)

            let totalNumbers = max(1, allNumbers.count)
            let columns = 9
            let rows = Int(ceil(Double(totalNumbers) / Double(columns)))

            let itemWidth = (availableWidth - CGFloat(columns - 1) * spacing) / CGFloat(columns)
            let itemHeight = (availableHeight - CGFloat(rows - 1) * spacing) / CGFloat(rows)

            let fontScale: CGFloat = compact ? 0.55 : 0.6
            let fontSize = max(8, min(itemWidth, itemHeight) * fontScale)

            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(itemWidth), spacing: spacing), count: columns),
                spacing: spacing
            ) {
                ForEach(allNumbers, id: \.self) { number in
                    Text("\(number)")
                        .font(.system(size: fontSize, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.3)
                        .allowsTightening(true)
                        .frame(width: itemWidth, height: itemHeight)
                        .background(drawnNumbers.contains(number) ? Color.green : Color.black.opacity(0.7))
                        .cornerRadius(max(4, min(itemWidth, itemHeight) * 0.12))
                        .foregroundColor(.white)
                }
            }
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .foregroundStyle(
                        Color.black.opacity(0.3)
                    )
            }
        }
    }
}
