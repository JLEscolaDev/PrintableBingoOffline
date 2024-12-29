//
//  PrintableBingoOfflineApp.swift
//  PrintableBingoOffline
//
//  Created by Jose Luis Escolá García on 18/12/24.
//

import SwiftUI

@main
struct PrintableBingoOfflineApp: App {
    @StateObject private var viewModel = BingoViewModel()
    @StateObject private var audioManager = AudioPlayerManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .onAppear {
                    audioManager.playIfEnabled()
                }
        }
        #if os(macOS)
        Settings {
            SettingsView()
                .environmentObject(viewModel) // Pasar el modelo también a los ajustes
        }
        #endif
    }
}
