//
//  SettingsView.swift
//  PrintableBingoOffline
//
//  Created by Jose Luis Escolá García on 28/12/24.
//

import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case en
    case es
    case fr
    case de

    var id: String { rawValue }

    var localeIdentifier: String? {
        switch self {
        case .system:
            return nil
        case .en, .es, .fr, .de:
            return rawValue
        }
    }

    var displayNameKey: LocalizedStringKey {
        switch self {
        case .system:
            return "settings.app_language.system"
        case .en:
            return "settings.app_language.en"
        case .es:
            return "settings.app_language.es"
        case .fr:
            return "settings.app_language.fr"
        case .de:
            return "settings.app_language.de"
        }
    }
}

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

    var appLanguage: AppLanguage = {
        let rawValue = UserDefaults.standard.string(forKey: "appLanguage") ?? AppLanguage.system.rawValue
        return AppLanguage(rawValue: rawValue) ?? .system
    }() {
        didSet {
            UserDefaults.standard.set(appLanguage.rawValue, forKey: "appLanguage")
            // Keep legacy flag in sync for backwards compatibility.
            UserDefaults.standard.set(effectiveLanguageCode == "en", forKey: "useEnglish")
            if !isJokesAvailable {
                shouldJoke = false
            }
            if !isDirtyModeAvailable {
                shouldGuarro = false
            }
        }
    }

    var appLocale: Locale? {
        guard let identifier = appLanguage.localeIdentifier else { return nil }
        return Locale(identifier: identifier)
    }

    var effectiveLanguageCode: String {
        switch appLanguage {
        case .system:
            let code = systemLanguageCode()
            return ["en", "es", "fr", "de"].contains(code) ? code : "es"
        case .en:
            return "en"
        case .es:
            return "es"
        case .fr:
            return "fr"
        case .de:
            return "de"
        }
    }

    var preferredVoiceAssetLanguage: String? {
        switch effectiveLanguageCode {
        case "en":
            return "English"
        case "es":
            return "Spanish"
        default:
            return nil
        }
    }

    var voiceLocaleIdentifier: String {
        switch effectiveLanguageCode {
        case "en":
            return "en-US"
        case "fr":
            return "fr-FR"
        case "de":
            return "de-DE"
        default:
            return "es-ES"
        }
    }

    var isDirtyModeAvailable: Bool {
        effectiveLanguageCode == "es"
    }

    var isJokesAvailable: Bool {
        effectiveLanguageCode == "es"
    }

    // MARK: - Default init
    private init() {
        if UserDefaults.standard.object(forKey: "drawInterval") == nil {
            drawInterval = 2.0
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
            maxNumber = 90
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
        if UserDefaults.standard.object(forKey: "appLanguage") == nil {
            appLanguage = .system
        }
        UserDefaults.standard.set(effectiveLanguageCode == "en", forKey: "useEnglish")
        if !isJokesAvailable {
            shouldJoke = false
        }
        if !isDirtyModeAvailable {
            shouldGuarro = false
        }
    }

    private func systemLanguageCode() -> String {
        if #available(iOS 16.0, macOS 13.0, *) {
            if let code = Locale.autoupdatingCurrent.language.languageCode?.identifier {
                return code.lowercased()
            }
        }
        let identifier = Locale.autoupdatingCurrent.identifier.lowercased()
        return String(identifier.prefix(2))
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var settings = SettingsManager.shared
    @StateObject private var audioManager = AudioPlayerManager.shared

    var body: some View {
        Form {
            Section(header: Text("settings.section.language")) {
                Picker("settings.app_language", selection: $settings.appLanguage) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayNameKey).tag(language)
                    }
                }
                .pickerStyle(.menu)
            }
            Section(header: Text("settings.section.draw")) {
                HStack {
                    Text("settings.interval_seconds")
                    Slider(value: $settings.drawInterval, in: 1...10, step: 1)
                    Text("\(Int(settings.drawInterval))s")
                }
                Picker("settings.max_number", selection: $settings.maxNumber) {
                    Text("90").tag(90)
                    Text("75").tag(75)
                }
            }
            Section(header: Text("settings.section.audio")) {
                Toggle("settings.sing_numbers", isOn: $settings.shouldSpeak)
                Toggle("settings.use_jokes", isOn: $settings.shouldJoke)
                    .disabled(!settings.isJokesAvailable)
                Toggle("settings.dirty_mode", isOn: $settings.shouldGuarro)
                    .disabled(!settings.isDirtyModeAvailable)
                HStack {
                    Text("settings.joke_frequency")
                    Slider(value: $settings.jokeFrequency, in: 0...1, step: 0.01)
                    Text("\(Int(settings.jokeFrequency * 100))%")
                        .frame(width: 50, alignment: .trailing)
                }
                .disabled(!settings.shouldJoke || !settings.isJokesAvailable)
            }
            Section(header: Text("settings.section.theme")) {
                Picker("settings.theme", selection: $settings.themeMode) {
                    ForEach(ThemeMode.allCases) { mode in
                        Text(LocalizedStringKey(mode.displayNameKey)).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
            Section(header: Text("settings.section.music")) {
                Toggle("settings.music", isOn: $settings.isMusicEnabled)
                    .toggleStyle(SwitchToggleStyle()) // Fuerza el estilo de switch verde
                    .onChange(of: settings.isMusicEnabled) { _, isEnabled in
                        if isEnabled {
                            audioManager.playIfEnabled()
                        } else {
                            audioManager.stopMusic()
                        }
                }
                HStack {
                    Text("settings.volume")
                    Slider(value: $settings.musicVolume, in: 0...1, step: 0.01)
                        .onChange(of: settings.musicVolume) { _, _ in
                            audioManager.applyPerceptualVolume()
                        }
                    Text("\(audioManager.effectiveVolumePercent())%")
                        .frame(width: 50, alignment: .trailing)
                }
            }
            Button("common.close") {
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
