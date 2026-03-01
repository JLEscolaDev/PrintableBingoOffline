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
    @StateObject private var creditsManager = CreditsManager()
    @StateObject private var purchaseManager = PurchaseManager()
    @StateObject private var adManager = AdManager()
    @Environment(\.scenePhase) var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .environmentObject(creditsManager)
                .environmentObject(purchaseManager)
                .environmentObject(adManager)
                .onAppear {
                    audioManager.playIfEnabled()
                    audioManager.applyPerceptualVolume()
                    #if os(iOS)
                    adManager.start()
                    #endif
                }
        }.onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                audioManager.playIfEnabled()
                audioManager.applyPerceptualVolume()
                #if os(iOS)
                adManager.start()
                #endif
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
