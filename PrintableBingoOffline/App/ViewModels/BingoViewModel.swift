//
//  BingoViewModel.swift
//  PrintableBingoOffline
//
//  Created by Jose Luis Escolá García on 28/12/24.
//

import AVFoundation
import SwiftUI

@MainActor
class BingoViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate, AVSpeechSynthesizerDelegate {
    private var settings = SettingsManager.shared
    private let audioManager = AudioPlayerManager.shared
    private let speechSynthesizer = AVSpeechSynthesizer()

    func allNumbers() -> [Int] {
        Array(1...settings.maxNumber)
    }
    
    @Published var drawnNumbers: [Int] = []
    @Published var isDrawing: Bool = false
    @Published var currentCaption: String? = nil
    @Published var didFinishGame: Bool = false

    private var availableNumbers: [Int] = []
    private var audioPlayer: AVAudioPlayer?
    private var audioData: AudioData?
    private var audioPlayerCompletion: (() -> Void)?
    private var ttsCompletion: (() -> Void)?

    override init() {
        super.init()
        speechSynthesizer.delegate = self
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
        didFinishGame = false
        stopDrawing()
    }

    func startDrawing() {
        guard !isDrawing else { return }
        if availableNumbers.isEmpty {
            availableNumbers = Array(1...settings.maxNumber)
            drawnNumbers = []
            didFinishGame = false
        }
        isDrawing = true
        drawAndSpeakNextNumber()
    }

    func stopDrawing() {
        isDrawing = false
        audioPlayer?.stop()
        speechSynthesizer.stopSpeaking(at: .immediate)
        audioPlayerCompletion = nil
        ttsCompletion = nil
        currentCaption = nil
        audioManager.unduckMusic()
    }

    private func drawAndSpeakNextNumber() {
        guard isDrawing else { return }
        guard let number = availableNumbers.randomElement() else {
            stopDrawing()
            didFinishGame = true
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

        let language = settings.useEnglish ? "English" : "Spanish"
        let numberAudio = "\(number)-\(language)"
        let commentSelection = selectComment(for: number)

        audioManager.duckMusic()
        playNumberAudio(fileName: numberAudio, number: number, language: language) {
            if let commentSelection {
                self.playCommentAudio(selection: commentSelection, preferredLanguage: language) {
                    self.audioManager.unduckMusic()
                    self.scheduleNextDraw()
                }
            } else {
                self.audioManager.unduckMusic()
                self.scheduleNextDraw()
            }
        }
    }

    private struct CommentSelection {
        let audioBase: String
        let text: String?
    }

    private func selectComment(for number: Int) -> CommentSelection? {
        guard settings.shouldJoke else { return nil }
        guard Double.random(in: 0...1) <= settings.jokeFrequency else { return nil }
        guard let audioEntry = audioData?.numbers[number] else { return nil }

        var audioFiles = settings.shouldGuarro ? audioEntry.audio.dirty : audioEntry.audio.comments
        var textOptions = settings.shouldGuarro ? audioEntry.text.dirty : audioEntry.text.comments

        if audioFiles.isEmpty {
            audioFiles = audioEntry.audio.comments
            textOptions = audioEntry.text.comments
        }

        guard !audioFiles.isEmpty else { return nil }
        let index = Int.random(in: 0..<audioFiles.count)
        let audioBase = audioFiles[index]
        let text = index < textOptions.count ? textOptions[index] : textOptions.randomElement()
        return CommentSelection(audioBase: audioBase, text: text)
    }

    private func playNumberAudio(fileName: String, number: Int, language: String, completion: @escaping () -> Void) {
        if Bundle.main.url(forResource: fileName, withExtension: "mp3") != nil {
            playAudio(from: fileName, completion: completion)
            return
        }

        if settings.useEnglish {
            speakNumberWithTTS(number: number, language: language, completion: completion)
            return
        }

        completion()
    }

    private func playCommentAudio(selection: CommentSelection, preferredLanguage: String, completion: @escaping () -> Void) {
        let resolvedFile = resolveCommentAudioFile(baseName: selection.audioBase, preferredLanguage: preferredLanguage)

        if let caption = selection.text {
            DispatchQueue.main.async {
                self.currentCaption = caption
            }
        }

        guard let resolvedFile else {
            DispatchQueue.main.async {
                self.currentCaption = nil
            }
            completion()
            return
        }

        playAudio(from: resolvedFile) {
            DispatchQueue.main.async {
                self.currentCaption = nil
            }
            completion()
        }
    }

    private func resolveCommentAudioFile(baseName: String, preferredLanguage: String) -> String? {
        let preferred = "\(baseName)-\(preferredLanguage)"
        if Bundle.main.url(forResource: preferred, withExtension: "mp3") != nil {
            return preferred
        }
        if preferredLanguage != "Spanish" {
            let spanish = "\(baseName)-Spanish"
            if Bundle.main.url(forResource: spanish, withExtension: "mp3") != nil {
                return spanish
            }
        }
        return nil
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

    private func speakNumberWithTTS(number: Int, language: String, completion: @escaping () -> Void) {
        let utterance = AVSpeechUtterance(string: "\(number)")
        let locale = language == "English" ? "en-US" : "es-ES"
        utterance.voice = AVSpeechSynthesisVoice(language: locale)
        utterance.rate = 0.48
        ttsCompletion = completion
        speechSynthesizer.speak(utterance)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if let completion = ttsCompletion {
            ttsCompletion = nil
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

        let resolvedTheme = ThemeResolver.resolvedTheme(for: Date(), mode: settings.themeMode)

        #if canImport(UIKit)
        let font = UIFont.systemFont(ofSize: 20)
        let borderColors = [
            UIColor.black.cgColor,
            UIColor.red.cgColor,
            UIColor.green.cgColor,
            UIColor.blue.cgColor
        ]
        let whiteColor = UIColor.white.cgColor
        #else
        let font = NSFont.systemFont(ofSize: 20)
        let borderColors = [
            NSColor.black.cgColor,
            NSColor.red.cgColor,
            NSColor.green.cgColor,
            NSColor.blue.cgColor
        ]
        let whiteColor = NSColor.white.cgColor
        #endif

        for _ in 0..<totalPages {
            pdfContext.beginPDFPage(nil)

            pdfContext.setFillColor(whiteColor)
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
                let placeholdersForCard = placeholdersForCard(theme: resolvedTheme, cardIndex: cardIndex)
                let bingoCard = generateBingoCard9x3(maxNumber: maxNumber, placeholders: placeholdersForCard)

                // Dibujar los números e iconos en el cartón
                drawBingoCard9x3(
                    context: pdfContext,
                    card: bingoCard,
                    originY: cardOriginY,
                    cardHeight: cardHeight,
                    pageWidth: pageWidth,
                    font: font,
                    placeholderTheme: resolvedTheme
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

    func generateBingoCard9x3(maxNumber: Int, placeholders: [String]) -> [[String]] {
        let rows = 3
        let columns = 9
        var bingoCard: [[Int?]] = Array(repeating: Array(repeating: nil, count: columns), count: rows)

        // Distribuir números en columnas por rangos (90 bolas usa rangos clásicos)
        let columnRanges = columnRangesFor(maxNumber: maxNumber, columns: columns)

        // 15 números por cartón, 5 por fila, 1–3 por columna
        var columnCounts = Array(repeating: 1, count: columns)
        var remaining = 15 - columns
        while remaining > 0 {
            let candidates = columnCounts.enumerated().filter { $0.element < 3 }.map { $0.offset }
            guard let index = candidates.randomElement() else { break }
            columnCounts[index] += 1
            remaining -= 1
        }

        var columnRowMap = Array(repeating: [Int](), count: columns)
        var success = false

        for _ in 0..<100 {
            columnRowMap = Array(repeating: [Int](), count: columns)
            var rowRemaining = Array(repeating: 5, count: rows)
            success = true

            let columnOrder = (0..<columns).sorted { columnCounts[$0] > columnCounts[$1] }
            for col in columnOrder {
                let count = columnCounts[col]
                let availableRows = (0..<rows).filter { rowRemaining[$0] > 0 }
                if availableRows.count < count {
                    success = false
                    break
                }
                let selectedRows = Array(availableRows.shuffled().prefix(count))
                columnRowMap[col] = selectedRows
                for row in selectedRows {
                    rowRemaining[row] -= 1
                }
            }

            if success && rowRemaining.allSatisfy({ $0 == 0 }) {
                break
            }
        }

        if success {
            for col in 0..<columns {
                let count = columnCounts[col]
                let numbers = Array(columnRanges[col]).shuffled().prefix(count).sorted()
                // En PDF el eje Y crece hacia arriba, por lo que la fila "superior"
                // es la de índice mayor. Para que el orden sea ascendente de arriba
                // a abajo, asignamos el menor a la fila más alta.
                let rowsForColumn = columnRowMap[col].sorted(by: >)
                for (rowIndex, number) in zip(rowsForColumn, numbers) {
                    bingoCard[rowIndex][col] = number
                }
            }
        }

        let fallback = placeholders.isEmpty ? "•" : placeholders[0]
        return bingoCard.map { row in
            row.map { value in
                guard let value else { return placeholders.randomElement() ?? fallback }
                return "\(value)"
            }
        }
    }

    func drawBingoCard9x3(context: CGContext, card: [[String]], originY: CGFloat, cardHeight: CGFloat, pageWidth: CGFloat, font: Any, placeholderTheme: ThemeMode) {
        let rows = 3
        let columns = 9
        let cellWidth = pageWidth / CGFloat(columns)
        let cellHeight = cardHeight / CGFloat(rows)

        #if canImport(UIKit)
        let strokeColor = UIColor.black.cgColor
        let textColor = UIColor.black
        #else
        let strokeColor = NSColor.black.cgColor
        let textColor = NSColor.black
        #endif

        for row in 0..<rows {
            for col in 0..<columns {
                let rect = CGRect(x: CGFloat(col) * cellWidth,
                                  y: originY + CGFloat(row) * cellHeight,
                                  width: cellWidth,
                                  height: cellHeight)

                // Dibujar el grid completo en negro
                context.setStrokeColor(strokeColor)
                context.setLineWidth(1)
                context.stroke(rect)

                let value = card[row][col]

                if value.rangeOfCharacter(from: .decimalDigits) != nil {
                    // Dibujar número
                    let attributes: [NSAttributedString.Key: Any] = [
                        .font: font,
                        .foregroundColor: textColor
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
                } else if !value.isEmpty {
                    // Dibujar icono en hueco
                    drawPlaceholderIcon(context: context, rect: rect, icon: value, theme: placeholderTheme)
                }
            }
        }
    }

    private func placeholderIcons(for theme: ThemeMode) -> [String] {
        switch theme {
        case .christmas:
            return ["🎄", "⭐️", "⛄️", "🎁", "❄️"]
        default:
            return ["●", "○", "◆", "■", "▲"]
        }
    }

    private func columnRangesFor(maxNumber: Int, columns: Int) -> [ClosedRange<Int>] {
        guard maxNumber > 0 else { return Array(repeating: 1...1, count: columns) }

        if maxNumber == 90 && columns == 9 {
            return [
                1...9, 10...19, 20...29, 30...39, 40...49,
                50...59, 60...69, 70...79, 80...90
            ]
        }

        let base = maxNumber / columns
        let remainder = maxNumber % columns
        var ranges: [ClosedRange<Int>] = []
        var start = 1

        for col in 0..<columns {
            let size = base + (col < remainder ? 1 : 0)
            let end = max(start, start + size - 1)
            ranges.append(start...end)
            start = end + 1
        }
        return ranges
    }

    private func placeholdersForCard(theme: ThemeMode, cardIndex: Int) -> [String] {
        let icons = placeholderIcons(for: theme)
        guard theme == .classic else { return icons }
        let icon = icons[cardIndex % icons.count]
        return [icon]
    }

    func drawPlaceholderIcon(context: CGContext, rect: CGRect, icon: String, theme: ThemeMode) {
        let iconFontSize = min(rect.width, rect.height) * 0.6
        #if canImport(UIKit)
        let font = UIFont.systemFont(ofSize: iconFontSize)
        let color: UIColor = theme == .christmas ? UIColor.red.withAlphaComponent(0.5) : UIColor.black.withAlphaComponent(0.25)
        #else
        let font = NSFont.systemFont(ofSize: iconFontSize)
        let color: NSColor = theme == .christmas ? NSColor.red.withAlphaComponent(0.5) : NSColor.black.withAlphaComponent(0.25)
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
