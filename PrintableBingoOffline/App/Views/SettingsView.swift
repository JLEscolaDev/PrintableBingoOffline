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

    var jokeFrequency: Double = UserDefaults.standard.double(forKey: "jokeFrequency") {
        didSet {
            UserDefaults.standard.set(jokeFrequency, forKey: "jokeFrequency")
        }
    }

    var shouldGuarro: Bool = UserDefaults.standard.bool(forKey: "shouldGuarro") {
        didSet {
            // It is mandatory to mark the shouldJoke if we want dirty jokes.
            if shouldGuarro {
                shouldJoke = true
            }
            UserDefaults.standard.set(shouldGuarro, forKey: "shouldGuarro")
        }
    }

    var useEnglish: Bool = UserDefaults.standard.bool(forKey: "useEnglish") {
        didSet {
            UserDefaults.standard.set(useEnglish, forKey: "useEnglish")
            shouldGuarro = false // There are no dirty rhymes for english version
        }
    }

    var themeMode: ThemeMode = {
        let rawValue = UserDefaults.standard.string(forKey: "themeMode") ?? ThemeMode.christmas.rawValue
        return ThemeMode(rawValue: rawValue) ?? .christmas
    }() {
        didSet {
            UserDefaults.standard.set(themeMode.rawValue, forKey: "themeMode")
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
        if UserDefaults.standard.object(forKey: "shouldJoke") == nil {
            shouldJoke = false
        }
        if UserDefaults.standard.object(forKey: "jokeFrequency") == nil {
            jokeFrequency = 0.05
        }
        if UserDefaults.standard.object(forKey: "maxNumber") == nil {
            maxNumber = 75
        }
        if UserDefaults.standard.object(forKey: "themeMode") == nil {
            themeMode = .christmas
        }
        if UserDefaults.standard.object(forKey: "isMusicEnabled") == nil {
            isMusicEnabled = true
        }
        if UserDefaults.standard.object(forKey: "musicVolume") == nil {
            musicVolume = 0.35
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
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
                HStack {
                    Text("Frecuencia de frases")
                    Slider(value: $settings.jokeFrequency, in: 0...1, step: 0.01)
                    Text("\(Int(settings.jokeFrequency * 100))%")
                        .frame(width: 50, alignment: .trailing)
                }
                .disabled(!settings.shouldJoke)
            }
            Section(header: Text("Idioma")) {
                Toggle("Usar Inglés", isOn: $settings.useEnglish)
            }
            Section(header: Text("Tema")) {
                Picker("Tema", selection: $settings.themeMode) {
                    ForEach(ThemeMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
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
                        .onChange(of: settings.musicVolume) { _, _ in
                            audioManager.applyPerceptualVolume()
                        }
                    Text("\(audioManager.effectiveVolumePercent())%")
                        .frame(width: 50, alignment: .trailing)
                }
            }
            Button("Cerrar") {
                dismiss()
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        #if os(macOS)
        .frame(minWidth: 340)
        #endif
    }
}
