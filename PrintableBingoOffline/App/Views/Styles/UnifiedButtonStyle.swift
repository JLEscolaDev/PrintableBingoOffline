//
//  UnifiedButtonStyle.swift
//  PrintableBingoOffline
//
//  Created by Jose Luis Escolá García on 31/12/24.
//

import SwiftUI

/// Button style for all platforms
struct UnifiedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let darkGray = Color(red: 58/256, green: 58/256, blue: 58/256)
        configuration.label
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .background(RoundedRectangle(cornerRadius: 10).fill(configuration.isPressed ? .gray : darkGray))
            .foregroundColor(.white)
            .font(.headline)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}
