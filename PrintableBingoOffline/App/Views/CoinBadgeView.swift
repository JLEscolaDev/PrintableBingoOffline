import SwiftUI

struct CoinBadgeView: View {
    let credits: Int
    let isPro: Bool

    var body: some View {
        HStack(spacing: 6) {
            if isPro {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                Text("PRO")
                    .fontWeight(.bold)
            } else {
                Image(systemName: "circle.fill")
                    .foregroundStyle(.yellow)
                Text("\(credits)")
                    .fontWeight(.bold)
            }
        }
        .font(.headline)
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            Capsule().fill(Color.black.opacity(0.6))
        )
        .foregroundStyle(.white)
    }
}
