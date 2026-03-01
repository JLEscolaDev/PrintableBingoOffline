//
//  LastDrawnNumbersView.swift
//  PrintableBingoOffline
//
//  Created by Jose Luis Escolá García on 28/12/24.
//

import SwiftUI

struct LastDrawnNumbersView: View {
    let drawnNumbers: [Int]
    var compact: Bool = false
    private let ballColors: [Color] = [
        .yellow, .blue, .red, .purple, .orange, .green, .black
    ]

    var body: some View {
        GeometryReader { geometry in
            // Detectar orientación
            let isPortrait = geometry.size.height > geometry.size.width
            let circleSize = if compact {
                min(geometry.size.height, geometry.size.width) / 3.8
            } else if isPortrait {
                geometry.size.height/5
            } else {
                geometry.size.width/5
            }
            VStack(alignment: .leading) {
                Text("Últimos 5 números:")
                    .font(compact ? .headline : .title)
                    .bold()
                    .shadow(radius: 2)
                    .padding(.bottom, compact ? 6 : 10)
                    .foregroundStyle(.white)
                    .padding(compact ? 12 : 20)
                    .background {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.black.opacity(compact ? 0.2 : 0.1))
                    }
                    .shadow(radius: 5)

                // Cambiar el layout dinámicamente
                if compact {
                    HStack(spacing: 8) {
                        ForEach(Array(drawnNumbers.suffix(5).reversed().enumerated()), id: \.element) { index, number in
                            ZStack {
                                BallView(number: number, color: ballColors[number % ballColors.count])
                                    .frame(width: circleSize - CGFloat(index * 6),
                                           height: circleSize - CGFloat(index * 6))
                                    .shadow(radius: 2)
                            }
                        }
                    }
                } else if isPortrait {
                    VStack(spacing: 10) {
                        ForEach(Array(drawnNumbers.suffix(5).reversed().enumerated()), id: \.element) { index, number in
                            ZStack {
                                BallView(number: number, color: ballColors[number % ballColors.count])
                                    .frame(width: circleSize - CGFloat(index * 10),
                                           height: circleSize - CGFloat(index * 10))
                                    .shadow(radius: 4)
                            }
                        }
                    }
                } else {
                    HStack(spacing: 10) {
                        ForEach(Array(drawnNumbers.suffix(5).reversed().enumerated()), id: \.element) { index, number in
                            ZStack {
                                BallView(number: number, color: ballColors[number % ballColors.count])
                                    .frame(width: circleSize - CGFloat(index * 10),
                                           height: circleSize - CGFloat(index * 10))
                                    .shadow(radius: 4)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .frame(minHeight: compact ? 140 : nil)
    }
}
