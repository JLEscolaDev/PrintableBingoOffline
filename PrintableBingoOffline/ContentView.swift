//
//  ContentView.swift
//  PrintableBingoOffline
//
//  Created by Jose Luis Escolá García on 18/12/24.
//

import SwiftUI

#Preview {
    ContentView()
}


import SwiftUI
import AVFoundation
#if canImport(UIKit)
import UIKit
#endif
import PDFKit

class BingoViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate { // Cambiado a AVAudioPlayerDelegate
    @AppStorage("drawInterval") var drawInterval: Double = 3.0 {
        didSet {
            // Si el sorteo está activo, no hacemos nada aquí ya que el próximo sorteo se programará después de que termine el actual
            print("Intervalo cambiado a \(drawInterval) segundos.")
        }
    }

    @AppStorage("maxNumber") var maxNumber: Int = 75
    @AppStorage("shouldSpeak") var shouldSpeak = true
    @AppStorage("shouldJoke") var shouldJoke = true
    @AppStorage("shouldGuarro") var shouldGuarro = false
    @AppStorage("useEnglish") var useEnglish = false {
        didSet {
            // Desactivar y deshabilitar guarros si el idioma es inglés.
            if useEnglish {
                shouldGuarro = false
            }
        }
    }
    
    @Published var allNumbers: [Int] = []
    @Published var drawnNumbers: [Int] = []
    @Published var isDrawing: Bool = false
    
    private var availableNumbers: [Int] = []
    private var audioPlayer: AVAudioPlayer? // Añadido AVAudioPlayer
    private let synthesizer = AVSpeechSynthesizer() // Eliminaremos esto si ya no se usa
    
    // Frases normales en Español (no modificar)
    private let normalCalls: [Int: [String]] = [
        1: ["El galán", "El pequeño"],
        2: ["El patito", "El sol"],
        3: ["San Cono, el Santo de la suerte"],
        4: ["La cama"],
        5: ["El galo", "La espina"],
        6: ["El perro", "El corazón"],
        7: ["El revólver", "La pipa", "La muleta"],
        8: ["El incendio", "La dama", "La señora gorda"],
        9: ["El zapato", "El arroyo"],
        10: ["La rosa", "El cañón"],
        11: ["Las banderillas", "El minero", "Los soldaditos"],
        12: ["El soldado"],
        13: ["La mala pata", "El número de la mala suerte"],
        14: ["El borracho", "La cerveza"],
        15: ["La niña bonita"],
        16: ["El anillo", "La guitarra"],
        17: ["La desgracia", "El barco de vela"],
        18: ["La sangre", "Los ojos", "El ramillete"],
        19: ["San José", "El Correo para Cuba"],
        20: ["La fiesta", "El tío del queso"],
        21: ["La mujer", "La primavera"],
        22: ["Los dos patitos"],
        23: ["El cocinero", "El melón"],
        24: ["El caballo", "Nochebuena"],
        25: ["Navidad"],
        26: ["La misa", "Los pollos"],
        27: ["El peine", "La pajarita", "La pajarera"],
        28: ["El cerro", "Alicante"],
        29: ["San Pedro", "El viaje"],
        30: ["Santa Rosa", "El león"],
        31: ["La luz", "Los caballos"],
        32: ["El dinero"],
        33: ["La edad de Cristo"],
        34: ["La cabeza", "El garrote"],
        35: ["El pajarito", "El fuego"],
        36: ["La castaña", "La sangre"],
        37: ["Los eucaliptos", "La espada"],
        38: ["Las piedras", "El perro"],
        39: ["La lluvia", "El toro"],
        40: ["El cura"],
        41: ["El cuchillo"],
        42: ["Las zapatillas"],
        43: ["El balcón", "La corona"],
        44: ["La cárcel", "Los tacones"],
        45: ["El vino"],
        46: ["Los tomates", "El sombrero"],
        47: ["El muerto"],
        48: ["El borrego", "La negra", "El muerto que habla"],
        49: ["La carne"],
        50: ["El pan"],
        51: ["El serrucho"],
        52: ["La madre y el hijo"],
        53: ["El barco"],
        54: ["La vaca"],
        55: ["Los civiles (Guardia Civil)"],
        56: ["La caída"],
        57: ["El jorobado"],
        58: ["El ahogado"],
        59: ["Las plantas"],
        60: ["La virgen"],
        61: ["La escopeta"],
        62: ["La inundación"],
        63: ["El casamiento"],
        64: ["El llanto"],
        65: ["El cazador"],
        66: ["La lombriz"],
        67: ["La mordida"],
        68: ["Los sobrinos"],
        69: ["Los vicios"],
        70: ["Los muertos", "El sueño"],
        71: ["El maestro", "El excremento"],
        72: ["La sorpresa"],
        73: ["El hospital"],
        74: ["La escalera"],
        75: ["Los besos"],
        76: ["Las llamas"],
        77: ["Las dos banderas"],
        78: ["La ramera"],
        79: ["El ladrón"],
        80: ["La bocha"],
        81: ["Las flores"],
        82: ["La pelea", "El jarro"],
        83: ["El mal tiempo"],
        84: ["La iglesia"],
        85: ["La linterna"],
        86: ["El humo"],
        87: ["Los piojos"],
        88: ["Las calabazas", "Las gordas"],
        89: ["La rata", "La gamba"],
        90: ["El abuelo (fin del juego)"]
    ]
    
    // Frases en Inglés (nuevas)
    private let normalCallsEnglish: [Int: [String]] = [
        1: ["Kelly's Eye"],
        2: ["One Little Duck"],
        3: ["Goodness Me"],
        4: ["Knock at the Door"],
        5: ["One Little Snake"],
        6: ["Tom Mix"],
        7: ["Lucky Seven"],
        8: ["Garden Gate"],
        9: ["Doctor's Orders"],
        10: ["Blind 10"],
        11: ["Legs Eleven"],
        12: ["A Monkey's Cousin"],
        13: ["Unlucky for Some"],
        14: ["Valentine's Day"],
        15: ["Young and Keen"],
        16: ["Sweet Sixteen"],
        17: ["Old Ireland"],
        18: ["Coming of Age"],
        19: ["Goodbye-Teens"],
        20: ["Blind 20, One Score"],
        21: ["Key to the Door"],
        22: ["Two Little Ducks"],
        23: ["Thee and Me"],
        24: ["Two Dozen"],
        25: ["Duck and Dive"],
        26: ["Pick 'n Mix"],
        27: ["Gateway to Heaven"],
        28: ["Overweight"],
        29: ["Rise and Shine"],
        30: ["Blind 30, Dirty Gertie"],
        31: ["Get up and Run"],
        32: ["Buckle my Shoe"],
        33: ["Blind Thirty, Three Feathers, Gertie Lee, Dirty Knee"],
        34: ["Ask for More"],
        35: ["Jump and Jive"],
        36: ["Three Dozen"],
        37: ["More than Eleven"],
        38: ["Christmas Cake"],
        39: ["Steps"],
        40: ["Blind Forty, Naughty Forty, Life Begins"],
        41: ["Time for Fun, Life’s Begun"],
        42: ["Winnie the Pooh"],
        43: ["Down on your Knee"],
        44: ["All the Fours, Droopy Drawers"],
        45: ["Halfway There"],
        46: ["Up to Tricks"],
        47: ["Four and Seven"],
        48: ["Four Dozen"],
        49: ["Rise and Shine"],
        50: ["Blind 50, It's a Bullseye, Half a Century"],
        51: ["Tweak of the Thumb"],
        52: ["Weeks of the Year"],
        53: ["Stuck in the Tree"],
        54: ["Clean the Floor"],
        55: ["Snakes Alive"],
        56: ["Shotts Bus"],
        57: ["Heinz Varieties"],
        58: ["Make Them Wait"],
        59: ["Brighton Line"],
        60: ["Blind 60, Five Dozen"],
        61: ["Bakers Bun"],
        62: ["Turn of the Screw"],
        63: ["Tickle Me"],
        64: ["Red Raw"],
        65: ["Old Age Pension"],
        66: ["Clickety Click"],
        67: ["Made in Heaven"],
        68: ["Pick a Mate, Saving Grace"],
        69: ["Either Way Up, Meal for Two"],
        70: ["Blind 70, Three Score & Ten"],
        71: ["Bang on the Drum"],
        72: ["Six Dozen, Par for the Course"],
        73: ["Queen Bee"],
        74: ["Candy Store"],
        75: ["Strive & Strive"],
        76: ["Trombones"],
        77: ["All the Sevens, Two Little Crutches"],
        78: ["Heavens Gate"],
        79: ["One More Time"],
        80: ["Blind 80, Ate Nothing, Gandhi's Breakfast"],
        81: ["Stop & Run"],
        82: ["Straight On Through"],
        83: ["Time for Tea, Ethel’s Ear"],
        84: ["Seven Dozen"],
        85: ["Staying Alive"],
        86: ["Between the Sticks"],
        87: ["Torquay in Devon"],
        88: ["All the Eights, Two Fat Ladies"],
        89: ["Nearly There"],
        90: ["Top of the Shop"]
    ]
    
    // Frases guarrotas (no cambiar)
    private let guarrosCalls: [Int: [String]] = [
        0: ["Te reviento el agujero."],
        1: ["Con mi pene te vacuno."],
        2: ["Te la meto como un dios."],
        3: ["Te la meto del revés."],
        4: ["Por tu culo mi aparato."],
        5: ["Por el culo te la hinco."],
        6: ["Si os agachais me la veis."],
        7: ["Te la meto en el retrete."],
        8: ["Por el culo te la embrocho."],
        9: ["En el culo se me mueve."],
        10: ["Chupamela otra vez."],
        11: ["La tengo de bronce."],
        12: ["Te la meto sin que roce."],
        13: ["En tu culo se me cuece."],
        14: ["Cuidado no la forces."],
        15: ["No me la hagas un esguince."],
        16: ["Me la cogeis la moveis."],
        17: ["Por la boca te la mete."],
        18: ["Por el culo te la entocho."],
        19: ["Ya tiene duro el pene."],
        20: ["Mi pene ya en tu mente."],
        21: ["La chupa como ninguno."],
        22: ["Te la meto sin adiós."],
        23: ["Te la coloco del revés."],
        24: ["Con dos huevos y mi aparato te dibujo tu retrato."],
        25: ["Por el culo te la hinco."],
        26: ["Si os arrodilláis me la veis."],
        27: ["Toca el saca y mete."],
        28: ["Te caliento el bizcocho."],
        29: ["Chupadita mientras bebe."],
        30: ["Se la meto a la parienta."],
        31: ["Te la comes como ninguno."],
        32: ["Te la meto y dices adiós."],
        33: ["Te la comes con interés."],
        34: ["Te la pongo en un rato."],
        35: ["Y vamos a por el bingo."],
        36: ["Esta os la coméis."],
        37: ["Yegua mía, te presento al jinete."],
        38: ["Te presento al pelocho"],
        39: ["Con suerte se te mueve."],
        40: ["Te la meto sin tormenta."],
        41: ["Con esta te rompo el ayuno."],
        42: ["Te dejo sin voz."],
        43: ["Te cojo con fluidez."],
        44: ["A aplaudir al cuarto."],
        45: ["Por el culo te la hinco."],
        46: ["A esta edad ya ni lo intentéis."],
        47: ["Entro con fuerza como si fuera un ariete."],
        48: ["Dura como palo de mocho"],
        49: ["Una tocadita leve"],
        50: ["Me la meto contenta."],
        51: ["Te la comes de desayuno."],
        52: ["Me la soplas como el lobo feroz"],
        53: ["Te la ajusto otra vez."],
        54: ["Te la meto de inmediato."],
        55: ["Por delante y por detrás para hacerlo distinto"],
        56: ["Si no os gusta no miréis"],
        57: ["Polvete en el retrete."],
        58: ["Me crece como a pinocho"],
        59: ["En el culo se te mueve"],
        60: ["Te la meto en la grieta."],
        61: ["La tengo gorda como luchador de sumo."],
        62: ["Las comes de dos en dos"],
        63: ["Te la sirvo con estrés."],
        64: ["Te ensarto de inmediato."],
        65: ["Tarariro tarariro"],
        66: ["Si os agacháis me la veis."],
        67: ["Te la meto en el retrete."],
        68: ["A una de comer chocho"],
        69: ["Por el culo te la hinco, la postura más perversa."],
        70: ["Te la meto sin afrenta."],
        71: ["Te la tragas con zumo."],
        72: ["Te la meto veloz."],
        73: ["Te la ajusto con fluidez."],
        74: ["Te la meto sin trato."],
        75: ["Por el culo te la hinco, sin descanso a los setenta y cinco."],
        76: ["Si te agachas me la veis."],
        77: ["Te la meto en el retrete."],
        78: ["Te la entocho con un poncho."],
        79: ["Te la chupo si llueve."],
        80: ["Te la meto sin tormenta."],
        81: ["Te la hundo sin ninguno."],
        82: ["Te la sirvo a dos en dos."],
        83: ["Te la pongo al revés."],
        84: ["Te la meto sin teatro."],
        85: ["Por el culo te la hinco, más profundo a los ochenta y cinco."],
        86: ["Si te agachas me la veis."],
        87: ["Te la meto en el retrete."],
        88: ["Te la entocho con un corcho."],
        89: ["Te penetro si llueve."],
        90: ["Te la meto con la cuenta."]
    ]

    private let genericPhrases = [
        "¡Atento que te puede tocar!",
        "¡A ver si esta vez tienes suerte!",
        "¡No te quedes atrás, apunta!",
        "¡Se acerca el premio!",
        "¡Esta puede ser la tuya!"
    ]
    
    override init() {
        super.init()
        // synthesizer.delegate = self // Eliminado ya que no usamos AVSpeechSynthesizer
        resetGame()
    }
    
    func resetGame() {
        availableNumbers = Array(1...maxNumber)
        drawnNumbers = []
        allNumbers = Array(1...maxNumber)
        stopDrawing()
    }
    
    func startDrawing() {
        guard !isDrawing else { return }
        isDrawing = true
        drawAndSpeakNextNumber() // Iniciar el proceso de sorteo
    }
    
    func stopDrawing() {
        isDrawing = false
        audioPlayer?.stop() // Detener cualquier audio en curso
    }
    
    private var audioPlayerCompletion: (() -> Void)?
    
    private func drawAndSpeakNextNumber() {
        guard isDrawing else { return }
        guard !availableNumbers.isEmpty else {
            stopDrawing()
            return
        }
        if let number = availableNumbers.randomElement() {
            let now = Date()
            print("Número sorteado: \(number) - Hora: \(now) - Intervalo actual: \(drawInterval) segundos")
            drawnNumbers.append(number)
            availableNumbers.removeAll(where: { $0 == number })
            speakNumberIfNeeded(number: number)
        } else {
            stopDrawing()
        }
    }
    
    private func speakNumberIfNeeded(number: Int) {
        guard shouldSpeak else {
            scheduleNextDraw()
            return
        }

        let language = useEnglish ? "English" : "Spanish"
        let mode = shouldGuarro ? "rhyme" : "Normal"

        // Define las subcarpetas para los archivos
        let numbersSubdirectory = "Resources/Voice/Numbers"
        let commentsSubdirectory = "Resources/Voice/Comments"

        // Define el nombre de los archivos
        let numberFileName = "\(number)-\(language)"
        let commentFileName = "\(number)-\(language)-\(mode)"

        let bundlePath = Bundle.main.bundlePath
        print("Bundle Path: \(bundlePath)")
        
//        let bundle = Bundle.main
//        guard let url = Bundle.main.url(forResource: "0-Spanish", withExtension: "mp3") else {
//                fatalError("Could not get URL for mp3 file!")
//            }
////                if let u = url {
////
////                    do {
//////                        sound = try AVAudioPlayer(contentsOf: u, fileTypeHint: AVFileType.mp3.rawValue)
//////                        sound.prepareToPlay()
//////                        sound.play()
////                        print("FUNCIONA")
////                    } catch let error {
//////                        print(error.localizedDescription)
////                        print("Could not find resource!")
////                    }
////
////                } else {
////                    print("Could not find resource!")
////                }
//
//        do {
//            let contents = try FileManager.default.contentsOfDirectory(atPath: bundlePath)
//            print("Contenido del Bundle: \(contents)")
//            if let voicePath = Bundle.main.path(forResource: "Voice", ofType: nil) {
//                print("Contenido de Voice: \(try FileManager.default.contentsOfDirectory(atPath: voicePath))")
//            }
//        } catch {
//            print("Error al listar el contenido del Bundle: \(error)")
//        }

        if let url = Bundle.main.url(forResource: "0-Spanish", withExtension: "mp3") {
            print("Archivo encontrado: \(url)")
        } else {
            print("Archivo NO encontrado en el Bundle.")
        }


        

        // Busca el archivo del número
        if let numberURL = Bundle.main.url(forResource: numberFileName, withExtension: "mp3") {
            print("Archivo de número encontrado: \(numberURL)")
            // Reproduce el archivo del número y, al terminar, reproduce el comentario
            playAudio(from: numberURL) {
                // Busca el archivo del comentario después de reproducir el número
                if let commentURL = Bundle.main.url(forResource: commentFileName, withExtension: nil, subdirectory: commentsSubdirectory) {
                    print("Archivo de comentario encontrado: \(commentURL)")
                    self.playAudio(from: commentURL) {
                        // Programa el siguiente sorteo después de reproducir el comentario
                        self.scheduleNextDraw()
                    }
                } else {
                    print("Archivo de comentario \(commentFileName) no encontrado en \(commentsSubdirectory)")
                    // Si no hay comentario, programa el siguiente sorteo
                    self.scheduleNextDraw()
                }
            }
        } else {
            print("Archivo de número \(numberFileName) no encontrado en \(numbersSubdirectory)")
            // Si no encuentra el archivo del número, intenta con un genérico
            let genericFileName = "generic-\(language).mp3"
            if let genericURL = Bundle.main.url(forResource: genericFileName, withExtension: nil, subdirectory: numbersSubdirectory) {
                print("Archivo genérico encontrado: \(genericURL)")
                playAudio(from: genericURL) {
                    self.scheduleNextDraw()
                }
            } else {
                print("Archivo genérico \(genericFileName) no encontrado en \(numbersSubdirectory)")
                scheduleNextDraw()
            }
        }
    }


    private func playAudio(from url: URL, completion: @escaping () -> Void) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self // Asignar delegado
            audioPlayer?.play()
            
            // Almacena la callback para ejecutarla al finalizar
            audioPlayerCompletion = completion
        } catch {
            print("Error al reproducir el archivo de audio: \(error)")
            completion() // Llama directamente a la callback en caso de error
        }
    }

    // Delegado de AVAudioPlayer para manejar el final de la reproducción
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Ejecuta la callback almacenada, si existe
        audioPlayerCompletion?()
        audioPlayerCompletion = nil
    }

    
    // Programar el siguiente sorteo después del intervalo
    private func scheduleNextDraw() {
        DispatchQueue.main.asyncAfter(deadline: .now() + drawInterval) {
            self.drawAndSpeakNextNumber()
        }
    }
    
    func generateBingoCards(numberOfCards: Int = 3) -> URL? {
        // Tamaño A4: ~595x842 puntos (72 DPI)
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
            
            // Fondo de la página en blanco
            pdfContext.setFillColor(CGColor.white)
            pdfContext.fill(mediaBox)
            
            for row in 0..<cardsPerPage {
                guard cardIndex < numberOfCards else { break }
                
                var numbersForCard = Array(1...maxNumber).shuffled().prefix(25)
                let gridSize = 5
                let cellWidth = pageWidth / CGFloat(gridSize)
                let cellHeight = cardHeight / CGFloat(gridSize)
                
                let cardOriginY = pageHeight - (CGFloat(row+1) * cardHeight)
                
                // Dibuja un rectángulo verde con borde rojo
                let cardRect = CGRect(x: 0, y: cardOriginY, width: pageWidth, height: cardHeight)
                pdfContext.setFillColor(CGColor(red: 0.9, green: 1.0, blue: 0.9, alpha: 1.0))
                pdfContext.fill(cardRect)
                
                pdfContext.setStrokeColor(CGColor(red: 1.0, green: 0, blue: 0, alpha: 1.0))
                pdfContext.setLineWidth(4)
                pdfContext.stroke(cardRect)
                
                // Adornos navideños
                let starSize: CGFloat = 20
                drawStar(in: pdfContext, at: CGPoint(x: cardRect.minX + 10, y: cardRect.maxY - 10 - starSize), size: starSize)
                drawStar(in: pdfContext, at: CGPoint(x: cardRect.maxX - 10 - starSize, y: cardRect.maxY - 10 - starSize), size: starSize)
                drawStar(in: pdfContext, at: CGPoint(x: cardRect.minX + 10, y: cardRect.minY + 10), size: starSize)
                drawStar(in: pdfContext, at: CGPoint(x: cardRect.maxX - 10 - starSize, y: cardRect.minY + 10), size: starSize)
                
                // Dibujar la cuadrícula y los números
                for r in 0..<gridSize {
                    for c in 0..<gridSize {
                        let rect = CGRect(x: CGFloat(c)*cellWidth,
                                          y: cardOriginY + CGFloat(r)*cellHeight,
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
                            let textRect = CGRect(x: rect.midX - textSize.width/2,
                                                  y: rect.midY - textSize.height/2,
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
        let radius = size/2.0
        let points = (0..<5).map { i -> CGPoint in
            let angle = (Double(i)*72.0 - 90.0)*Double.pi/180.0
            return CGPoint(x: c.x + CGFloat(cos(angle))*radius, y: c.y + CGFloat(sin(angle))*radius)
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

// MARK: - Tambor View

struct TamborView: View {
    @State private var rotation: Angle = .degrees(0)
    
    var body: some View {
        Image(.bingoDrum)
            .resizable()
//            .fill(Color.blue)
            .frame(width: 150, height: 150)
            .padding(.leading, 20)
//            .rotationEffect(rotation)
//            .onAppear {
//                withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
//                    rotation = .degrees(360)
//                }
//            }
    }
}

// MARK: - Last Drawn Numbers View

import SwiftUI

import SwiftUI

struct LastDrawnNumbersView: View {
    let drawnNumbers: [Int]
    private let ballColors: [Color] = [
        .yellow, .blue, .red, .purple, .orange, .green, .black
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Últimos 5 números:")
                .font(.largeTitle)
                .bold()
                .shadow(radius: 2)
                .padding(.bottom, 10)
                .foregroundStyle(.white)
                .padding(20)
                .background {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.black.opacity(0.1))
                        
                }
                .shadow(radius: 5)
            
            VStack(spacing: 10) {
                ForEach(Array(drawnNumbers.suffix(5).reversed().enumerated()), id: \.element) { index, number in
                    ZStack {
                        BallView(number: number, color: ballColors[number % ballColors.count])
                            .frame(width: CGFloat(100 - (index * 5)), height: CGFloat(100 - (index * 5)))
                            .shadow(radius: 4)
                    }
                }
            }
        }
        .padding()
    }
}


struct BallView: View {
    let number: Int
    let color: Color
    @State private var rotation: Angle = .degrees(0)
    
    var body: some View {
        ZStack {
            // Fondo principal de la bola
            Circle()
                .fill(color)
            
            // Bandas blancas aleatorias recortadas a la bola
            Circle()
                .fill(Color.clear)
                .overlay(
                    Canvas { context, size in
                        let rect = CGRect(origin: .zero, size: size)
                        
                        // Generar posición y tamaño aleatorios para las bandas
                        let randomRotation = CGFloat.random(in: -60...60)
                        let randomOffset = CGFloat.random(in: -4...4)
                        
                        // Bandas superiores e inferiores
                        let bandHeight = size.height * 0.4
                        let bandWidth = size.width * 2.6 // Más ancho para dar efecto de "envolver"
                        
                        let topBand = CGRect(
                            x: rect.midX - bandWidth / 2 + randomOffset,
                            y: rect.minY,
                            width: bandWidth,
                            height: bandHeight
                        )
                        
                        let bottomBand = CGRect(
                            x: rect.midX - bandWidth / 2 - randomOffset,
                            y: rect.maxY - bandHeight,
                            width: bandWidth,
                            height: bandHeight
                        )
                        
                        // Aplicar rotación aleatoria
                        context.rotate(by: Angle(degrees: randomRotation))
                        
                        context.fill(
                            Path(ellipseIn: topBand),
                            with: .color(.white.opacity(0.7))
                        )
                        context.fill(
                            Path(ellipseIn: bottomBand),
                            with: .color(.white.opacity(0.7))
                        )
                    }
                    .clipShape(Circle()) // Recortar las bandas al círculo de la bola
                )
            
            // Área blanca central para el número
            Circle()
                .fill(Color.white)
                .frame(width: 55, height: 55)
            
            // Número
            Text("\(number)")
                .font(.system(size: 35))
                .bold()
                .foregroundColor(.black)
        }
        .overlay(
            Circle()
                .stroke(Color.black, lineWidth: 2) // Bordes de la bola
        )
        .rotationEffect(rotation)
        .onAppear {
            withAnimation(Animation.bouncy(duration: 0.2)) {
                let randomRotation = Double.random(in: -20.0...20.0)
                rotation = .degrees(randomRotation)
            }
        }
    }
}



// MARK: - Numbers Grid View

struct NumbersGridView: View {
    let allNumbers: [Int]
    let drawnNumbers: [Int]

    var body: some View {
        GeometryReader { geometry in
            // Calcular el número de columnas basado en el ancho disponible
            let columnsCount = max(3, Int(geometry.size.width / 60)) // Cada celda ocupa ~60 puntos de ancho
            let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: columnsCount)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(allNumbers, id: \.self) { number in
                        Text("\(number)")
                            .frame(minWidth: 40, minHeight: 40) // Ajustar el tamaño mínimo de las celdas
                            .background(drawnNumbers.contains(number) ? Color.green : Color.black.opacity(0.7))
                            .cornerRadius(4)
                            .foregroundColor(.white) // Para que el texto sea legible
                    }
                }
                .padding()
            }
        }
    }
}


// MARK: - Settings View

struct SettingsView: View {
    @AppStorage("drawInterval") var drawInterval: Double = 5.0
    @AppStorage("maxNumber") var maxNumber: Int = 75
    @AppStorage("shouldSpeak") var shouldSpeak = true
    @AppStorage("shouldJoke") var shouldJoke = true
    @AppStorage("shouldGuarro") var shouldGuarro = false
    @AppStorage("useEnglish") var useEnglish = false // Nuevo toggle
    
    var body: some View {
        Form {
            Section(header: Text("Ajustes de sorteo")) {
                HStack {
                    Text("Intervalo (s)")
                    Slider(value: $drawInterval, in: 1...10, step: 1)
                    Text("\(Int(drawInterval))s")
                }
                
                Picker("Número Máximo", selection: $maxNumber) {
                    Text("75").tag(75)
                    Text("90").tag(90)
                }
            }
            
            Section(header: Text("Ajustes de audio")) {
                Toggle("Cantar Números", isOn: $shouldSpeak)
                Toggle("Usar bromas / frases", isOn: $shouldJoke)
                Toggle("Modo Guarro", isOn: $shouldGuarro)
                    .disabled(useEnglish) // Deshabilitar si está en inglés
            }
            Section(header: Text("Idioma")) {
                Toggle("Usar Inglés", isOn: $useEnglish)
            }
        }
        .padding()
        #if os(macOS)
        .frame(width: 300)
        #endif
    }
}

// MARK: - Main Content View

import SwiftUI
import SpriteKit

class SnowScene: SKScene {

    let snowEmitterNode = SKEmitterNode(fileNamed: "Snow.sks")

    override func didMove(to view: SKView) {
        guard let snowEmitterNode = snowEmitterNode else { return }
        snowEmitterNode.particleSize = CGSize(width: 50, height: 50)
        snowEmitterNode.particleLifetime = 2
        snowEmitterNode.particleLifetimeRange = 6
        addChild(snowEmitterNode)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard let snowEmitterNode = snowEmitterNode else { return }
        snowEmitterNode.particlePosition = CGPoint(x: size.width/2, y: size.height)
        snowEmitterNode.particlePositionRange = CGVector(dx: size.width, dy: size.height)
    }
}

struct ContentView: View {
    @StateObject var viewModel = BingoViewModel()
    @State private var showSettings = false
    
    var body: some View {
        #if os(macOS)
        mainContent
        #else
        mainContent
            .toolbar {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gear")
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        #endif
    }
    
    
    var scene: SKScene {
        let scene = SnowScene()
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
        return scene
    }
    @State private var currentBackground: String = "ChristmasBackground1"
    
    var mainContent: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                ZStack {
                    UnevenRoundedRectangle(cornerRadii: .init(bottomLeading: 20, bottomTrailing: 20, topTrailing: 20))
                        .fill(.black.opacity(0.8))
                        .frame(width: 200, height: 100)
                    VStack {
                        HStack {
                            Button("Start") {
                                viewModel.startDrawing()
                            }
                            Button("Stop") {
                                viewModel.stopDrawing()
                            }
                            Button("Reset") {
                                viewModel.resetGame()
                                currentBackground = "ChristmasBackground\(Int.random(in: 1...10))"
                            }
                        }
                        Button("Generar Cartones PDF") {
                            if let url = viewModel.generateBingoCards() {
#if os(macOS)
                                NSWorkspace.shared.activateFileViewerSelecting([url])
#elseif os(iOS)
                                // Para iOS, podrías presentar un UIActivityViewController
                                // Implementación adicional requerida
                                let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                                UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true, completion: nil)
#endif
                            }
                        }
                    }
                }
                TamborView()
                LastDrawnNumbersView(drawnNumbers: viewModel.drawnNumbers)
                
            }
            NumbersGridView(allNumbers: viewModel.allNumbers, drawnNumbers: viewModel.drawnNumbers)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding()
        .background {
            GeometryReader { geometry in
                ZStack {
                    Image(currentBackground)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped() // Asegura que el fondo no se salga de los límites

                    VStack {
                            HStack(spacing: -100) {
                                Image(.cloud1)
                                    .resizable()
                                    .frame(width: 300, height: 300)
                                    .offset(x: 200) // Ajusta el desplazamiento vertical para no salirte del límite
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
                                    .offset(x: -200)
                            }
                        SpriteView(scene: scene, options: [.allowsTransparency])
                                        .ignoresSafeArea()
                                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                                        .offset(y: -180)
                        Spacer()
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .offset(x: 100)
                }
            }
            .ignoresSafeArea() // Asegura que todo se expanda al área segura
        }    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
