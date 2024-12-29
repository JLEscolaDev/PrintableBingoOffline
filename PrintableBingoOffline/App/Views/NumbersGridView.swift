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

    var body: some View {
        GeometryReader { geometry in
            let spacing: CGFloat = 10
            let padding: CGFloat = 20

            // Proporción de la vista
            let aspectRatio = geometry.size.width / geometry.size.height

            // Calcular número ideal de columnas basándonos en la proporción
            let totalNumbers = allNumbers.count
            let idealColumns = Int(sqrt(Double(totalNumbers) * Double(aspectRatio)))
            let idealRows = Int(ceil(Double(totalNumbers) / Double(idealColumns)))

            // Tamaño de los elementos ajustado al espacio disponible
            let itemWidth = (geometry.size.width - padding*2 - CGFloat(idealColumns + 1) * spacing) / CGFloat(idealColumns)
            let itemHeight = (geometry.size.height - padding*2 - CGFloat(idealRows + 1) * spacing) / CGFloat(idealRows)

            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.fixed(itemWidth), spacing: spacing), count: idealColumns),
                    spacing: spacing
                ) {
                    ForEach(allNumbers, id: \.self) { number in
                        Text("\(number)")
                            .font(.largeTitle)
                            .bold()
                            .minimumScaleFactor(0.5)
                            .frame(width: itemWidth, height: itemHeight)
                            .background(drawnNumbers.contains(number) ? Color.green : Color.black.opacity(0.7))
                            .cornerRadius(min(itemWidth, itemHeight) * 0.1)
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
