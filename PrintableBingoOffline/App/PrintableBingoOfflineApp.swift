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
    @Environment(\.scenePhase) var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .onAppear {
                    audioManager.playIfEnabled()
                }
        }.onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                audioManager.playIfEnabled()
            } else {
                audioManager.stopMusic()
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
