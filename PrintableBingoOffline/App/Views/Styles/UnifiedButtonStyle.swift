//
//  UnifiedButtonStyle.swift
//  PrintableBingoOffline
//
//  Created by Jose Luis Escolá García on 31/12/24.
//

import SwiftUI

/// Button style for all platforms
struct UnifiedButtonStyle: ButtonStyle {
    var compact: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        let darkGray = Color(red: 58/256, green: 58/256, blue: 58/256)
        configuration.label
            .padding(.vertical, compact ? 4 : 6)
            .padding(.horizontal, compact ? 8 : 12)
            .background(RoundedRectangle(cornerRadius: 10).fill(configuration.isPressed ? .gray : darkGray))
            .foregroundColor(.white)
            .font(compact ? .subheadline : .headline)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}
