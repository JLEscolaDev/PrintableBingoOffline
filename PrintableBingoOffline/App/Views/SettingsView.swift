//
//  SettingsView.swift
//  PrintableBingoOffline
//
//  Created by Jose Luis Escolá García on 28/12/24.
//

import SwiftUI

@Observable
class SettingsManager {
    // MARK: - Singleton
    static let shared = SettingsManager()

    // MARK: - Configuración Persistente
    var drawInterval: Double = UserDefaults.standard.double(forKey: "drawInterval") {
        didSet {
            UserDefaults.standard.set(drawInterval, forKey: "drawInterval")
        }
    }

    var maxNumber: Int = UserDefaults.standard.integer(forKey: "maxNumber") {
        didSet {
            UserDefaults.standard.set(maxNumber, forKey: "maxNumber")
        }
    }

    var shouldSpeak: Bool = UserDefaults.standard.bool(forKey: "shouldSpeak") {
        didSet {
            UserDefaults.standard.set(shouldSpeak, forKey: "shouldSpeak")
        }
    }

    var shouldJoke: Bool = UserDefaults.standard.bool(forKey: "shouldJoke") {
        didSet {
            UserDefaults.standard.set(shouldJoke, forKey: "shouldJoke")
        }
    }

    var shouldGuarro: Bool = UserDefaults.standard.bool(forKey: "shouldGuarro") {
        didSet {
            UserDefaults.standard.set(shouldGuarro, forKey: "shouldGuarro")
        }
    }

    var useEnglish: Bool = UserDefaults.standard.bool(forKey: "useEnglish") {
        didSet {
            UserDefaults.standard.set(useEnglish, forKey: "useEnglish")
            shouldGuarro = false // There are no dirty rhymes for english version
        }
    }
    
    var isMusicEnabled: Bool = UserDefaults.standard.bool(forKey: "isMusicEnabled") {
        didSet {
            UserDefaults.standard.set(isMusicEnabled, forKey: "isMusicEnabled")
        }
    }
    
    var musicVolume: Float = UserDefaults.standard.float(forKey: "musicVolume") {
        didSet {
            UserDefaults.standard.set(musicVolume, forKey: "musicVolume")
        }
    }

    // MARK: - Default init
    private init() {
        if UserDefaults.standard.object(forKey: "drawInterval") == nil {
            drawInterval = 5.0
        }
        if UserDefaults.standard.object(forKey: "shouldSpeak") == nil {
            shouldSpeak = true
        }
        if UserDefaults.standard.object(forKey: "maxNumber") == nil {
            maxNumber = 75
        }
        if UserDefaults.standard.object(forKey: "isMusicEnabled") == nil {
            isMusicEnabled = true
        }
        if UserDefaults.standard.object(forKey: "musicVolume") == nil {
            musicVolume = 0.15
        }
    }
}

struct SettingsView: View {
    #if os(iOS) || os(visionOS)
    @Environment(\.dismiss) var dismiss
    #endif
    @State private var settings = SettingsManager.shared
    @StateObject private var audioManager = AudioPlayerManager.shared

    var body: some View {
        Form {
            Section(header: Text("Ajustes de sorteo")) {
                HStack {
                    Text("Intervalo (s)")
                    Slider(value: $settings.drawInterval, in: 1...10, step: 1)
                    Text("\(Int(settings.drawInterval))s")
                }
                Picker("Número Máximo", selection: $settings.maxNumber) {
                    Text("75").tag(75)
                    Text("90").tag(90)
                }
            }
            Section(header: Text("Ajustes de audio")) {
                Toggle("Cantar Números", isOn: $settings.shouldSpeak)
                Toggle("Usar bromas / frases", isOn: $settings.shouldJoke)
                Toggle("Modo Guarro", isOn: $settings.shouldGuarro)
                    .disabled(settings.useEnglish)
            }
            Section(header: Text("Idioma")) {
                Toggle("Usar Inglés", isOn: $settings.useEnglish)
            }
            Section(header: Text("Música de Fondo")) {
                Toggle("Música", isOn: $settings.isMusicEnabled)
                    .toggleStyle(SwitchToggleStyle()) // Fuerza el estilo de switch verde
                    .onChange(of: settings.isMusicEnabled) { _, isEnabled in
                        if isEnabled {
                            audioManager.playIfEnabled()
                        } else {
                            audioManager.stopMusic()
                        }
                    }
                HStack {
                    Text("Volumen")
                    Slider(value: $settings.musicVolume, in: 0...1, step: 0.01)
                    Text("\(Int(audioManager.volume() * 100))%")
                }
            }
            #if os(iOS) || os(visionOS)
            Button("Aceptar") {
                dismiss()
            }.frame(maxWidth: .infinity)
            #endif
        }
        .padding()
        #if os(macOS)
        .frame(width: 300)
        #endif
    }
}
