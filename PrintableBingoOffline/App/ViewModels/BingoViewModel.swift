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

    func generateBingoCards(numberOfCards: Int = 30, cardsPerPage: Int = 3, maxNumber: Int = 90) -> URL? {
        let pageWidth: CGFloat = 595
        let pageHeight: CGFloat = 842
        let cardHeight = (pageHeight / CGFloat(cardsPerPage)) - 10 // Dejar un margen vertical entre cartones
        let margin: CGFloat = 5 // Margen entre cartones

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

        let borderColors: [CGColor] = [
            CGColor(red: 0, green: 0, blue: 0, alpha: 1), // Negro
            CGColor(red: 1, green: 0, blue: 0, alpha: 1), // Rojo
            CGColor(red: 0, green: 1, blue: 0, alpha: 1), // Verde
            CGColor(red: 0, green: 0, blue: 1, alpha: 1)  // Azul
        ]

        for _ in 0..<totalPages {
            pdfContext.beginPDFPage(nil)

            pdfContext.setFillColor(CGColor.white)
            pdfContext.fill(mediaBox)

            for row in 0..<cardsPerPage {
                guard cardIndex < numberOfCards else { break }

                let cardOriginY = pageHeight - (CGFloat(row + 1) * (cardHeight + margin))

                let cardRect = CGRect(x: 0, y: cardOriginY, width: pageWidth, height: cardHeight)

                // Elegir color del borde
                let borderColor = borderColors.randomElement()!

                // Rellenar el fondo del cartón con el color del borde y opacidad 0.1
                pdfContext.setFillColor(borderColor.copy(alpha: 0.1)!)
                pdfContext.fill(cardRect)

                // Dibujar el borde exterior del cartón con el color del borde
                pdfContext.setStrokeColor(borderColor)
                pdfContext.setLineWidth(12) // Grosor del borde
                pdfContext.stroke(cardRect)

                // Generar números del cartón con huecos vacíos e iconos
                let bingoCard = generateBingoCard9x3(maxNumber: maxNumber)

                // Dibujar los números e iconos en el cartón
                drawBingoCard9x3(
                    context: pdfContext,
                    card: bingoCard,
                    originY: cardOriginY,
                    cardHeight: cardHeight,
                    pageWidth: pageWidth,
                    font: font
                )

                cardIndex += 1
            }

            pdfContext.endPDFPage()
        }

        pdfContext.closePDF()

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("BingoCards.pdf")
        pdfData.write(to: tempURL, atomically: true)
        return tempURL
    }

    func drawOuterBorder(context: CGContext, rect: CGRect, color: CGColor) {
        context.setStrokeColor(color)
        context.setLineWidth(12) // Grosor del borde
        context.stroke(rect) // Dibujar borde exterior encima del grid
    }

    func generateBingoCard9x3(maxNumber: Int) -> [[String]] {
        let rows = 3
        let columns = 9
        var bingoCard: [[String?]] = Array(repeating: Array(repeating: nil, count: columns), count: rows)

        // Distribuir números en columnas por rangos
        let columnRanges = [
            1...9, 10...19, 20...29, 30...39, 40...49,
            50...59, 60...69, 70...79, 80...90
        ]

        for col in 0..<columns {
            let columnNumbers = Array(columnRanges[col]).shuffled().prefix(3).sorted(by: >) // Ordenar ascendentemente
            for row in 0..<3 {
                bingoCard[row][col] = "\(columnNumbers[row])"
            }
        }

        // Asegurar 5 números por fila con huecos intercalados
        let icons = ["🎄", "⭐️", "⛄️", "🎁", "❄️"]
        for row in 0..<rows {
            // Extraer las posiciones ocupadas
            var filledIndices = bingoCard[row].enumerated().compactMap { $0.element != nil ? $0.offset : nil }
            while filledIndices.count > 5 {
                let indexToClear = filledIndices.randomElement()!
                bingoCard[row][indexToClear] = icons.randomElement()!
                filledIndices.removeAll { $0 == indexToClear }
            }
        }

        // Convertir nil a iconos navideños (para celdas vacías)
        return bingoCard.map { $0.map { $0 ?? icons.randomElement()! } }
    }

    func drawBingoCard9x3(context: CGContext, card: [[String]], originY: CGFloat, cardHeight: CGFloat, pageWidth: CGFloat, font: Any) {
        let rows = 3
        let columns = 9
        let cellWidth = pageWidth / CGFloat(columns)
        let cellHeight = cardHeight / CGFloat(rows)

        for row in 0..<rows {
            for col in 0..<columns {
                let rect = CGRect(x: CGFloat(col) * cellWidth,
                                  y: originY + CGFloat(row) * cellHeight,
                                  width: cellWidth,
                                  height: cellHeight)

                // Dibujar el grid completo en negro
                context.setStrokeColor(CGColor.black)
                context.setLineWidth(1)
                context.stroke(rect)

                let value = card[row][col]

                if value.rangeOfCharacter(from: .decimalDigits) != nil {
                    // Dibujar número
                    #if canImport(UIKit)
                    let color = UIColor.black
                    #else
                    let color = NSColor.black
                    #endif
                    let attributes: [NSAttributedString.Key: Any] = [
                        .font: font,
                        .foregroundColor: color
                    ]
                    let attrString = NSAttributedString(string: value, attributes: attributes)
                    let textSize = attrString.size()
                    let textRect = CGRect(x: rect.midX - textSize.width / 2,
                                          y: rect.midY - textSize.height / 2,
                                          width: textSize.width,
                                          height: textSize.height)
                    let line = CTLineCreateWithAttributedString(attrString)
                    context.textPosition = CGPoint(x: textRect.minX, y: textRect.minY)
                    CTLineDraw(line, context)
                } else {
                    // Dibujar icono navideño
                    drawChristmasIcon(context: context, rect: rect, icon: value)
                }
            }
        }
    }

    func drawChristmasIcon(context: CGContext, rect: CGRect, icon: String) {
        let iconFontSize = min(rect.width, rect.height) * 0.6
        #if canImport(UIKit)
        let font = UIFont.systemFont(ofSize: iconFontSize)
        let color = UIColor.red.withAlphaComponent(0.5)
        #else
        let font = NSFont.systemFont(ofSize: iconFontSize)
        let color = NSColor.red.withAlphaComponent(0.5)
        #endif
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]

        let attrString = NSAttributedString(string: icon, attributes: attributes)
        let textSize = attrString.size()
        let textRect = CGRect(x: rect.midX - textSize.width / 2,
                              y: rect.midY - textSize.height / 2,
                              width: textSize.width,
                              height: textSize.height)
        let line = CTLineCreateWithAttributedString(attrString)
        context.textPosition = CGPoint(x: textRect.minX, y: textRect.minY)
        CTLineDraw(line, context)
    }
}
