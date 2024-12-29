//
//  TamborView.swift
//  PrintableBingoOffline
//
//  Created by Jose Luis Escolá García on 28/12/24.
//

import SwiftUI

struct TamborView: View {
    @State private var rotation: Angle = .degrees(0)

    var body: some View {
        Image(.bingoDrum)
            .resizable()
            .frame(width: 150, height: 150)
            .padding(.leading, 20)
    }
}
