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

            let totalNumbers = allNumbers.count

            // Compute columns, itemWidth, itemHeight as a single expression to avoid
            // mutable assignments inside the ViewBuilder.
            let layout: (columns: Int, itemWidth: CGFloat, itemHeight: CGFloat) = {
                if compact {
                    // En compacto priorizamos legibilidad y dejamos que el grid haga scroll.
                    let minCell: CGFloat = 26
                    let columns = max(6, Int((availableWidth + spacing) / (minCell + spacing)))
                    let itemWidth = (availableWidth - CGFloat(columns - 1) * spacing) / CGFloat(columns)
                    let itemHeight = itemWidth * 0.9
                    return (columns, itemWidth, itemHeight)
                } else {
                    // Proporción de la vista
                    let aspectRatio = geometry.size.width / max(1, geometry.size.height)

                    // Calcular número ideal de columnas basándonos en la proporción
                    let idealColumns = max(8, Int(sqrt(Double(totalNumbers) * Double(aspectRatio))))
                    let idealRows = Int(ceil(Double(totalNumbers) / Double(idealColumns)))

                    // Tamaño de los elementos ajustado al espacio disponible
                    let itemWidth = (availableWidth - CGFloat(idealColumns - 1) * spacing) / CGFloat(idealColumns)
                    let itemHeight = (geometry.size.height - padding * 2 - CGFloat(idealRows - 1) * spacing) / CGFloat(idealRows)
                    return (idealColumns, itemWidth, itemHeight)
                }
            }()

            let columns = layout.columns
            let itemWidth = layout.itemWidth
            let itemHeight = layout.itemHeight

            let fontScale: CGFloat = compact ? 0.52 : 0.6
            let fontSize = max(9, min(itemWidth, itemHeight) * fontScale)

            ScrollView {
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
                .padding(spacing)
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
