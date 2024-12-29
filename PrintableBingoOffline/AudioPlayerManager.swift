// AudioPlayerManager.swift
// This manager now controls two separate AVAudioPlayers: one for music and one for voice audio.
// It also has separate volume controls and methods to play each type of audio independently.
// Comments in English as requested.

//import AVFoundation
//import SwiftUI
//
//@Observable
//class AudioPlayerManager: NSObject {
//    private var audioPlayerMusic: AVAudioPlayer?
//    private var audioPlayerVoice: AVAudioPlayer?
//
//    // Separate volumes for music and voice
//    private(set) var musicVolume: Float = 1.0 {
//        didSet {
//            audioPlayerMusic?.volume = musicVolume
//        }
//    }
//
//    private(set) var voiceVolume: Float = 1.0 {
//        didSet {
//            audioPlayerVoice?.volume = voiceVolume
//        }
//    }
//
//    // Play music files
//    func playMusic(songName: String) {
//        if let soundURL = Bundle.main.url(forResource: songName, withExtension: "mp3") {
//            do {
//                audioPlayerMusic = try AVAudioPlayer(contentsOf: soundURL)
//                audioPlayerMusic?.enableRate = true
//                audioPlayerMusic?.numberOfLoops = 0
//                audioPlayerMusic?.volume = musicVolume
//                audioPlayerMusic?.prepareToPlay()
//                audioPlayerMusic?.play()
//            } catch {
//                print("Error playing music: \(error)")
//            }
//        } else {
//            print("Music file not found: \(songName)")
//        }
//    }
//
//    func stopMusic() {
//        audioPlayerMusic?.stop()
//    }
//
//    func setMusicVolume(_ value: Float) {
//        let clamped = max(0, min(value, 1.0))
//        musicVolume = clamped
//    }
//
//    // Play voice files
//    // Completion is called when voice finishes playing.
//    func playVoiceAudio(from url: URL, completion: @escaping () -> Void) {
//        do {
//            audioPlayerVoice = try AVAudioPlayer(contentsOf: url)
//            audioPlayerVoice?.delegate = self
//            audioPlayerVoice?.volume = voiceVolume
//            audioPlayerVoice?.prepareToPlay()
//            voiceCompletion = completion
//            audioPlayerVoice?.play()
//        } catch {
//            print("Error playing voice audio: \(error)")
//            completion()
//        }
//    }
//
//    func setVoiceVolume(_ value: Float) {
//        let clamped = max(0, min(value, 1.0))
//        voiceVolume = clamped
//    }
//
//    // A stored completion block for voice audio
//    private var voiceCompletion: (() -> Void)?
//
//    func stopVoiceAudio() {
//        audioPlayerVoice?.stop()
//        voiceCompletion = nil
//    }
//}
//
//extension AudioPlayerManager: AVAudioPlayerDelegate {
//    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
//        if player == audioPlayerVoice, let completion = voiceCompletion {
//            voiceCompletion = nil
//            completion()
//        }
//    }
//}

import AVFoundation
import SwiftUI

@MainActor
class AudioPlayerManager: NSObject, ObservableObject {
    static let shared = AudioPlayerManager()

    private var audioPlayer: AVAudioPlayer?
    private var savedTime: TimeInterval = 0
    private(set) var currentSong: String?
    private(set) var playbackRate: Float = 1.0
    @Published var volume: Float = 1.0 {
        didSet {
            audioPlayer?.volume = volume
        }
    }

    // Lista de canciones
    let songList = [
        "Bingo Bells", "Bingo Bells2", "Bingo Bells3", "Bingo Bells4",
        "Bingo Night Delight", "Bingo Night Delight2",
        "Christmas Bingo", "Christmas Bingo2",
        "Holiday Bingo", "Holiday Bingo2",
        "Holiday Dreams", "Jolly Bingo Christmas", "Jolly Bingo Christmas2",
        "Silent Nightfall", "Silent Nightfall2", "Silent Snow Serenade", "Silent Snow Serenade2"
    ]

    // MARK: - Reproducir una canción específica
    func playSong(named songName: String) {
        guard let soundURL = Bundle.main.url(forResource: songName, withExtension: "mp3") else {
            print("Archivo de música no encontrado: \(songName)")
            return
        }
        print("Archivo encontrado: \(soundURL)")
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.delegate = self
            audioPlayer?.enableRate = true
            audioPlayer?.rate = playbackRate
            audioPlayer?.volume = volume
            audioPlayer?.prepareToPlay()
            if audioPlayer?.play() == true {
                print("Reproducción iniciada correctamente.")
            } else {
                print("Error al iniciar la reproducción.")
            }
            currentSong = songName
        } catch {
            print("Error al reproducir la canción \(songName): \(error)")
        }
    }

    // MARK: - Reproducir una canción aleatoria
    func playRandomSong() {
        guard let randomSong = songList.randomElement() else {
            print("No hay canciones disponibles en la lista.")
            return
        }
        playSong(named: randomSong)
    }
    
    func playIfEnabled() {
        if SettingsManager.shared.isMusicEnabled {
            playRandomSong()
        }
    }

    // MARK: - Detener la música
    func stopMusic() {
        savedTime = audioPlayer?.currentTime ?? 0
        audioPlayer?.stop()
        audioPlayer = nil
        currentSong = nil
        print("Música detenida.")
    }

    // MARK: - Cambiar el volumen
    func setVolume(to value: Float) {
        volume = max(0, min(value, 1.0)) // Asegurar que esté entre 0 y 1
    }

    // MARK: - Cambiar la velocidad de reproducción
    func increasePlaybackRate() {
        playbackRate = min(playbackRate + 0.2, 2.0)
        audioPlayer?.rate = playbackRate
    }

    func decreasePlaybackRate() {
        playbackRate = max(playbackRate - 0.2, 0.5)
        audioPlayer?.rate = playbackRate
    }
}

extension AudioPlayerManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("Canción finalizada: \(currentSong ?? "desconocida")")
        playRandomSong() // Reproduce otra canción automáticamente
    }
}
