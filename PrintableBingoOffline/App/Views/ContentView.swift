//
//  ContentView.swift
//  PrintableBingoOffline
//
//  Created by Jose Luis Escolá García on 18/12/24.
//

import SwiftUI
import SpriteKit

struct ContentView: View {
    @EnvironmentObject var viewModel: BingoViewModel // Modelo compartido
    @State private var showSettings = false
    @State private var currentBackground: String = "ChristmasBackground1"

    var body: some View {
        #if os(macOS)
        mainContent
        #else
        mainContent
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(viewModel) // Pasar explícitamente el modelo
            }
        #endif
    }

    var mainContent: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                HStack {
                    VStack {
                        HStack {
                            Button("Start") {
                                viewModel.startDrawing()
                            }
                            .buttonStyle(UnifiedButtonStyle())
                            
                            Button("Stop") {
                                viewModel.stopDrawing()
                            }
                            .buttonStyle(UnifiedButtonStyle())
                            
                            Button("Reset") {
                                viewModel.resetGame()
                                currentBackground = "ChristmasBackground\(Int.random(in: 1...10))"
                            }
                            .buttonStyle(UnifiedButtonStyle())
                        }
                        Button("Generar Cartones PDF") {
                            if let url = viewModel.generateBingoCards() {
                                #if os(macOS)
                                NSWorkspace.shared.activateFileViewerSelecting([url])
                                #elseif os(iOS)
                                let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                                UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true, completion: nil)
                                #endif
                            }
                        }.buttonStyle(UnifiedButtonStyle())
                    }
                    #if os(iOS)
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                            .resizable()
                            .frame(width: 50, height: 50)
                    }.buttonStyle(UnifiedButtonStyle())
                    #endif
                }
                .padding(16)
                .background {
                    UnevenRoundedRectangle(cornerRadii: .init(bottomLeading: 20, bottomTrailing: 20, topTrailing: 20))
                        .fill(.black.opacity(0.8))
                }
                #if os(macOS)
                TamborView()
                #endif
                LastDrawnNumbersView(drawnNumbers: viewModel.drawnNumbers)
            }
            NumbersGridView(allNumbers: viewModel.allNumbers(), drawnNumbers: viewModel.drawnNumbers)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding()
        .background {
            GeometryReader { geometry in
                ZStack {
                    // Fondo de la imagen actual
                    Image(currentBackground)
                        .resizable()
                        .scaledToFill()
//                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .ignoresSafeArea()
                    VStack {
                        // Nubes animadas
                        HStack(spacing: -100) {
                            Image(.cloud1)
                                .resizable()
                                .frame(width: 300, height: 300)
                                .offset(x: 200)
                            Image(.cloud2)
                                .resizable()
                                .frame(width: 600, height: 300)
                            Image(.cloud2)
                                .resizable()
                                .frame(width: 600, height: 300)
                                .offset(x: -100)
                            Image(.cloud3)
                                .resizable()
                                .frame(width: 300, height: 300)
                                .offset(x: -100)
                        }
                        // Animación de nieve con SpriteKit
                        SpriteView(scene: scene, options: [.allowsTransparency])
                            .offset(y: -180)
                            .frame(minWidth: 0, maxWidth: 1000, minHeight: 0, maxHeight: geometry.size.height)
                            .ignoresSafeArea()
                        Spacer()
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
        }
    }

    var scene: SKScene {
        let scene = SnowScene()
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
        return scene
    }
}

