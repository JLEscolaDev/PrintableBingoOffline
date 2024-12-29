import AVFoundation
import SwiftUI

@MainActor
class AudioPlayerManager: NSObject, ObservableObject {
    static let shared = AudioPlayerManager()
    private let settings = SettingsManager.shared

    private var audioPlayer: AVAudioPlayer?
    private var savedTime: TimeInterval = 0
    private(set) var currentSong: String?
    private(set) var playbackRate: Float = 1.0
    func volume() -> Float {
        audioPlayer?.volume = settings.musicVolume
        return settings.musicVolume
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
            audioPlayer?.volume = volume()
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
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.playRandomSong() // Reproduce new random song in main actor
        }
    }
}
