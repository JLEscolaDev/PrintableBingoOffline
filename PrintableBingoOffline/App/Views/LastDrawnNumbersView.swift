//
//  LastDrawnNumbersView.swift
//  PrintableBingoOffline
//
//  Created by Jose Luis Escolá García on 28/12/24.
//

import SwiftUI

struct LastDrawnNumbersView: View {
    let drawnNumbers: [Int]
    private let ballColors: [Color] = [
        .yellow, .blue, .red, .purple, .orange, .green, .black
    ]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Últimos 5 números:")
                .font(.largeTitle)
                .bold()
                .shadow(radius: 2)
                .padding(.bottom, 10)
                .foregroundStyle(.white)
                .padding(20)
                .background {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.black.opacity(0.1))
                }
                .shadow(radius: 5)

            VStack(spacing: 10) {
                ForEach(Array(drawnNumbers.suffix(5).reversed().enumerated()), id: \.element) { index, number in
                    ZStack {
                        BallView(number: number, color: ballColors[number % ballColors.count])
                            .frame(width: CGFloat(100 - (index * 5)), height: CGFloat(100 - (index * 5)))
                            .shadow(radius: 4)
                    }
                }
            }
        }
        .padding()
    }
}
