//
//  BingoViewModel.swift
//  PrintableBingoOffline
//
//  Created by Jose Luis Escolá García on 28/12/24.
//

import AVFoundation
import SwiftUI

class BingoViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @State private var settings = SettingsManager.shared
    
    func allNumbers() -> [Int] {
        Array(1...settings.maxNumber)
    }
    
    @Published var drawnNumbers: [Int] = []
    @Published var isDrawing: Bool = false

    private var availableNumbers: [Int] = []
    private var audioPlayer: AVAudioPlayer?
    private var audioData: AudioData?
    private var audioPlayerCompletion: (() -> Void)?

    override init() {
        super.init()
        loadAudioData()
        resetGame()
    }

    private func loadAudioData() {
        guard let url = Bundle.main.url(forResource: "bingo_data", withExtension: "json") else {
            print("Error: Could not find bingo_data.json in bundle.")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            audioData = try JSONDecoder().decode(AudioData.self, from: data)
        } catch {
            print("Error decoding audio data: \(error)")
        }
    }

    func resetGame() {
        availableNumbers = Array(1...settings.maxNumber)
        drawnNumbers = []
        stopDrawing()
    }

    func startDrawing() {
        guard !isDrawing else { return }
        isDrawing = true
        drawAndSpeakNextNumber()
    }

    func stopDrawing() {
        isDrawing = false
        audioPlayer?.stop()
    }

    private func drawAndSpeakNextNumber() {
        guard isDrawing, let number = availableNumbers.randomElement() else {
            stopDrawing()
            return
        }

        drawnNumbers.append(number)
        availableNumbers.removeAll { $0 == number }
        speakNumberIfNeeded(number: number)
    }

    private func speakNumberIfNeeded(number: Int) {
        guard settings.shouldSpeak else {
            scheduleNextDraw()
            return
        }

        let mode = settings.shouldGuarro ? "dirty" : "comments"
        let language = settings.useEnglish ? "English" : "Spanish"
        let numberAudio = "\(number)-\(language)"

        if let audioEntry = audioData?.numbers[number] {
            let commentFiles = mode == "dirty" ? audioEntry.audio.dirty : audioEntry.audio.comments

            if let commentFile = commentFiles.first {
                let commentAudio = "\(commentFile)-\(language)"
                // Play number audio first, then the comment
                playAudio(from: numberAudio) {
                    self.playAudio(from: commentAudio) {
                        self.scheduleNextDraw()
                    }
                }
            } else {
                // Only play the number audio if no comment is available
                playAudio(from: numberAudio) {
                    self.scheduleNextDraw()
                }
            }
        } else {
            print("Audio not found for number: \(number)")
            scheduleNextDraw()
        }
    }

    private func playAudio(from fileName: String, completion: @escaping () -> Void) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
            print("Audio file \(fileName) not found in bundle")
            completion()
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            audioPlayerCompletion = completion
        } catch {
            print("Error playing audio file: \(error)")
            completion()
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if let completion = audioPlayerCompletion {
            audioPlayerCompletion = nil
            completion()
        }
    }

    private func scheduleNextDraw() {
        DispatchQueue.main.asyncAfter(deadline: .now() + settings.drawInterval) {
            self.drawAndSpeakNextNumber()
        }
    }

    func generateBingoCards(numberOfCards: Int = 3) -> URL? {
        let pageWidth: CGFloat = 595
        let pageHeight: CGFloat = 842
        let cardsPerPage = 3
        let cardHeight = pageHeight / CGFloat(cardsPerPage)

        let pdfData = NSMutableData()
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData) else { return nil }
        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        guard let pdfContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return nil }

        let totalPages = Int(ceil(Double(numberOfCards) / Double(cardsPerPage)))
        var cardIndex = 0

        #if canImport(UIKit)
        let font = UIFont.systemFont(ofSize: 20)
        #else
        let font = NSFont.systemFont(ofSize: 20)
        #endif

        for _ in 0..<totalPages {
            pdfContext.beginPDFPage(nil)

            pdfContext.setFillColor(CGColor.white)
            pdfContext.fill(mediaBox)

            for row in 0..<cardsPerPage {
                guard cardIndex < numberOfCards else { break }

                var numbersForCard = Array(1...settings.maxNumber).shuffled().prefix(25)
                let gridSize = 5
                let cellWidth = pageWidth / CGFloat(gridSize)
                let cellHeight = cardHeight / CGFloat(gridSize)

                let cardOriginY = pageHeight - (CGFloat(row + 1) * cardHeight)

                let cardRect = CGRect(x: 0, y: cardOriginY, width: pageWidth, height: cardHeight)
                pdfContext.setFillColor(CGColor(red: 0.9, green: 1.0, blue: 0.9, alpha: 1.0))
                pdfContext.fill(cardRect)

                pdfContext.setStrokeColor(CGColor(red: 1.0, green: 0, blue: 0, alpha: 1.0))
                pdfContext.setLineWidth(4)
                pdfContext.stroke(cardRect)

                let starSize: CGFloat = 20
                drawStar(in: pdfContext, at: CGPoint(x: cardRect.minX + 10, y: cardRect.maxY - 10 - starSize), size: starSize)
                drawStar(in: pdfContext, at: CGPoint(x: cardRect.maxX - 10 - starSize, y: cardRect.maxY - 10 - starSize), size: starSize)
                drawStar(in: pdfContext, at: CGPoint(x: cardRect.minX + 10, y: cardRect.minY + 10), size: starSize)
                drawStar(in: pdfContext, at: CGPoint(x: cardRect.maxX - 10 - starSize, y: cardRect.minY + 10), size: starSize)

                for r in 0..<gridSize {
                    for c in 0..<gridSize {
                        let rect = CGRect(x: CGFloat(c) * cellWidth,
                                          y: cardOriginY + CGFloat(r) * cellHeight,
                                          width: cellWidth,
                                          height: cellHeight)
                        pdfContext.setStrokeColor(CGColor.black)
                        pdfContext.setLineWidth(1)
                        pdfContext.stroke(rect)

                        if let number = numbersForCard.popFirst() {
                            let numberStr = "\(number)"
                            #if canImport(UIKit)
                            let attributes: [NSAttributedString.Key: Any] = [
                                .font: font,
                                .foregroundColor: UIColor.black
                            ]
                            #else
                            let attributes: [NSAttributedString.Key: Any] = [
                                .font: font,
                                .foregroundColor: NSColor.black
                            ]
                            #endif

                            let attrString = NSAttributedString(string: numberStr, attributes: attributes)
                            let textSize = attrString.size()
                            let textRect = CGRect(x: rect.midX - textSize.width / 2,
                                                  y: rect.midY - textSize.height / 2,
                                                  width: textSize.width,
                                                  height: textSize.height)
                            let line = CTLineCreateWithAttributedString(attrString)
                            pdfContext.textPosition = CGPoint(x: textRect.minX, y: textRect.minY)
                            CTLineDraw(line, pdfContext)
                        }
                    }
                }

                cardIndex += 1
            }

            pdfContext.endPDFPage()
        }

        pdfContext.closePDF()

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("BingoCards.pdf")
        pdfData.write(to: tempURL, atomically: true)
        return tempURL
    }

    private func drawStar(in context: CGContext, at point: CGPoint, size: CGFloat) {
        let c = point
        let radius = size / 2.0
        let points = (0..<5).map { i -> CGPoint in
            let angle = (Double(i) * 72.0 - 90.0) * Double.pi / 180.0
            return CGPoint(x: c.x + CGFloat(cos(angle)) * radius, y: c.y + CGFloat(sin(angle)) * radius)
        }
        let starPath = CGMutablePath()
        starPath.move(to: points[0])
        starPath.addLine(to: points[2])
        starPath.addLine(to: points[4])
        starPath.addLine(to: points[1])
        starPath.addLine(to: points[3])
        starPath.closeSubpath()

        context.setFillColor(CGColor(red: 1.0, green: 0, blue: 0, alpha: 1.0))
        context.addPath(starPath)
        context.fillPath()
    }
}
