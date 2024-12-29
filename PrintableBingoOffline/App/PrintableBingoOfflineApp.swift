//
//  PrintableBingoOfflineApp.swift
//  PrintableBingoOffline
//
//  Created by Jose Luis Escolá García on 18/12/24.
//

import SwiftUI
import AVFAudio

//@main
//struct PrintableBingoOfflineApp: App {
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
//        #if os(macOS)
//        Settings {
//            SettingsView()
//        }
//        #endif
//    }
//}




@main
struct PrintableBingoOfflineApp: App {
    @StateObject private var viewModel = BingoViewModel() // Instancia compartida
    @StateObject private var audioManager = AudioPlayerManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel) // Pasar el modelo al árbol de vistas
                .onAppear {
                    audioManager.playIfEnabled() // Inicia la música automáticamente
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






//@main
//struct PrintableBingoOfflineApp: App {
//    @StateObject private var viewModel = BingoViewModel() // Instancia compartida
//
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//                .environmentObject(viewModel) // Proveer a ContentView
//        }
//        #if os(macOS)
//        Settings {
//            SettingsView()
//                .environmentObject(viewModel) // Proveer a SettingsView
//        }
//        #endif
//    }
//}
//
//class BingoViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
//    @AppStorage("drawInterval") var drawIntervalStorage: Double = 3.0 {
//        didSet {
//            drawInterval = drawIntervalStorage
//        }
//    }
//    @Published var drawInterval: Double = 3.0
//
//    @AppStorage("maxNumber") var maxNumberStorage: Int = 75 {
//        didSet {
//            maxNumber = maxNumberStorage
//        }
//    }
//    @Published var maxNumber: Int = 75
//
//    @AppStorage("shouldSpeak") var shouldSpeakStorage: Bool = true {
//        didSet {
//            shouldSpeak = shouldSpeakStorage
//        }
//    }
//    @Published var shouldSpeak: Bool = true
//
//    @AppStorage("shouldJoke") var shouldJokeStorage: Bool = true {
//        didSet {
//            shouldJoke = shouldJokeStorage
//        }
//    }
//    @Published var shouldJoke: Bool = true
//
//    @AppStorage("shouldGuarro") var shouldGuarroStorage: Bool = false {
//        didSet {
//            shouldGuarro = shouldGuarroStorage
//        }
//    }
//    @Published var shouldGuarro: Bool = false
//
//    @AppStorage("useEnglish") var useEnglishStorage: Bool = false {
//        didSet {
//            useEnglish = useEnglishStorage
//            if useEnglish {
//                shouldGuarro = false
//            }
//        }
//    }
//    @Published var useEnglish: Bool = false
//
//    override init() {
//        super.init()
//        // Inicializa propiedades sincronizadas
//        drawInterval = drawIntervalStorage
//        maxNumber = maxNumberStorage
//        shouldSpeak = shouldSpeakStorage
//        shouldJoke = shouldJokeStorage
//        shouldGuarro = shouldGuarroStorage
//        useEnglish = useEnglishStorage
//    }
//}
//struct SettingsView: View {
//    @EnvironmentObject var viewModel: BingoViewModel
//
//    var body: some View {
//        Form {
//            Section(header: Text("Ajustes de sorteo")) {
//                HStack {
//                    Text("Intervalo (s)")
//                    Slider(value: $viewModel.drawInterval, in: 1...10, step: 1)
//                    Text("\(Int(viewModel.drawInterval))s")
//                }
//
//                Picker("Número Máximo", selection: $viewModel.maxNumber) {
//                    Text("75").tag(75)
//                    Text("90").tag(90)
//                }
//            }
//
//            Section(header: Text("Ajustes de audio")) {
//                Toggle("Cantar Números", isOn: $viewModel.shouldSpeak)
//                Toggle("Usar bromas / frases", isOn: $viewModel.shouldJoke)
//                Toggle("Modo Guarro", isOn: $viewModel.shouldGuarro)
//                    .disabled(viewModel.useEnglish)
//            }
//
//            Section(header: Text("Idioma")) {
//                Toggle("Usar Inglés", isOn: $viewModel.useEnglish)
//            }
//        }
//        .padding()
//        #if os(macOS)
//        .frame(width: 300)
//        #endif
//    }
//}
//struct ContentView: View {
//    @EnvironmentObject var viewModel: BingoViewModel // Obtener el modelo desde el entorno
//    @State private var showSettings = false
//
//    var body: some View {
//        #if os(macOS)
//        mainContent
//        #else
//        mainContent
//            .toolbar {
//                Button {
//                    showSettings = true
//                } label: {
//                    Image(systemName: "gear")
//                }
//            }
//            .sheet(isPresented: $showSettings) {
//                SettingsView() // SettingsView ya recibe el modelo automáticamente
//            }
//        #endif
//    }
//
//    var mainContent: some View {
//        VStack {
//            Text("Intervalo de sorteo: \(viewModel.drawInterval, specifier: "%.1f") segundos")
//            Text("Número máximo: \(viewModel.maxNumber)")
//            // Otros componentes de la interfaz
//        }
//        .padding()
//    }
//}
//
