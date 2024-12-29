//
//  BallView.swift
//  PrintableBingoOffline
//
//  Created by Jose Luis Escolá García on 28/12/24.
//

import SwiftUI

struct BallView: View {
    let number: Int
    let color: Color
    @State private var rotation: Angle = .degrees(0)

    var body: some View {
        ZStack {
            Circle().fill(color)
            Circle()
                .fill(Color.clear)
                .overlay(
                    Canvas { context, size in
                        let rect = CGRect(origin: .zero, size: size)
                        let randomRotation = CGFloat.random(in: -60...60)
                        let randomOffset = CGFloat.random(in: -4...4)
                        let bandHeight = size.height * 0.4
                        let bandWidth = size.width * 2.6

                        let topBand = CGRect(
                            x: rect.midX - bandWidth / 2 + randomOffset,
                            y: rect.minY,
                            width: bandWidth,
                            height: bandHeight
                        )

                        let bottomBand = CGRect(
                            x: rect.midX - bandWidth / 2 - randomOffset,
                            y: rect.maxY - bandHeight,
                            width: bandWidth,
                            height: bandHeight
                        )

                        context.rotate(by: Angle(degrees: randomRotation))
                        context.fill(Path(ellipseIn: topBand), with: .color(.white.opacity(0.7)))
                        context.fill(Path(ellipseIn: bottomBand), with: .color(.white.opacity(0.7)))
                    }
                    .clipShape(Circle())
                )

            Circle()
                .fill(Color.white)
                .frame(width: 55, height: 55)
            Text("\(number)")
                .font(.system(size: 35))
                .bold()
                .foregroundColor(.black)
        }
        .overlay(
            Circle().stroke(Color.black, lineWidth: 2)
        )
        .rotationEffect(rotation)
        .onAppear {
            withAnimation(Animation.bouncy(duration: 0.2)) {
                let randomRotation = Double.random(in: -20.0...20.0)
                rotation = .degrees(randomRotation)
            }
        }
    }
}
