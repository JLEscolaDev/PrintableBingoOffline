//
//  ContentView.swift
//  PrintableBingoOffline
//
//  Created by Jose Luis Escolá García on 18/12/24.
//

import SpriteKit
import SwiftUI

#if os(iOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct ContentView: View {
    private enum Screen {
        case home
        case game
    }

    @EnvironmentObject private var viewModel: BingoViewModel
    @EnvironmentObject private var creditsManager: CreditsManager
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @EnvironmentObject private var adManager: AdManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var showCoffeeSupport = false
    @State private var paywallReason: PaywallReason = .insufficientCoins
    @State private var rotatingThemeBackground: String = "ChristmasBackground1"
    @State private var currentScreen: Screen = .home
    @State private var settings = SettingsManager.shared

    var body: some View {
        ZStack {
            themedBackground
            if currentScreen == .home {
                homeContent
            } else {
                gameContent
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(reason: paywallReason)
                .environmentObject(creditsManager)
                .environmentObject(purchaseManager)
                .environmentObject(adManager)
                #if os(macOS)
                .frame(minWidth: 560, idealWidth: 640, minHeight: 520, idealHeight: 620)
                #endif
        }
        .sheet(isPresented: $showCoffeeSupport) {
            CoffeeSupportView()
                .environmentObject(creditsManager)
                .environmentObject(purchaseManager)
                #if os(macOS)
                .frame(minWidth: 420, idealWidth: 460)
                #endif
        }
        .onChange(of: viewModel.didFinishGame) { _, finished in
            guard finished else { return }
            viewModel.didFinishGame = false
            guard !purchaseManager.isPro else { return }
            paywallReason = .postGame
            showPaywall = true
        }
        .onChange(of: settings.themeMode) { _, _ in
            refreshRotatingThemeBackground()
        }
        .onAppear {
            refreshRotatingThemeBackground()
        }
    }

    private var homeContent: some View {
        GeometryReader { geometry in
            let wideLayout = geometry.size.width > 780

            VStack(spacing: 24) {
                Spacer(minLength: wideLayout ? 40 : 24)

                VStack(spacing: 12) {
                    Text("Printable Bingo Offline")
                        .font(wideLayout ? .largeTitle.bold() : .title.bold())
                        .foregroundStyle(.white)

                    Text(purchaseManager.isPro ? "Modo Pro activo. Juega sin límites." : "Juega rápido, recarga monedas cuando quieras y desbloquea Pro cuando te compense.")
                        .font(wideLayout ? .title3 : .body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.85))
                        .frame(maxWidth: 680)
                }

                CoinBadgeView(credits: creditsManager.credits, isPro: purchaseManager.isPro)

                VStack(spacing: 14) {
                    Button {
                        openGameScreen()
                    } label: {
                        Label(viewModel.isResumingCurrentGame ? "Continuar partida" : "Jugar", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(UnifiedButtonStyle())

                    Button {
                        openPaywall()
                    } label: {
                        Label("Conseguir monedas", systemImage: "star.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(UnifiedButtonStyle())

                    HStack(spacing: 12) {
                        Button {
                            showSettings = true
                        } label: {
                            Label("Ajustes", systemImage: "gear")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(UnifiedButtonStyle())

                        Button {
                            showCoffeeSupport = true
                        } label: {
                            Label("Invítame a un café", systemImage: "cup.and.saucer.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(UnifiedButtonStyle())
                    }
                }
                .frame(maxWidth: wideLayout ? 460 : .infinity)

                Spacer()
            }
            .padding(.horizontal, wideLayout ? 40 : 20)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var gameContent: some View {
        GeometryReader { geometry in
            let isCompact = (horizontalSizeClass == .compact) || geometry.size.width < 700
            let useSingleRowCompactTopBar: Bool = {
                #if os(iOS)
                UIDevice.current.userInterfaceIdiom == .phone &&
                geometry.size.width > geometry.size.height &&
                geometry.size.width >= 620
                #else
                false
                #endif
            }()

            if isCompact {
                VStack(alignment: .leading, spacing: 12) {
                    topBarCompact(singleRow: useSingleRowCompactTopBar)
                    lastNumbersCompact
                    captionView(compact: true)
                    NumbersGridView(allNumbers: viewModel.allNumbers(), drawnNumbers: viewModel.drawnNumbers, compact: true)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding()
            } else {
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 16) {
                        topBarRegular
                        TamborView()
                        LastDrawnNumbersView(drawnNumbers: viewModel.drawnNumbers)
                        captionView(compact: false)
                        Spacer()
                    }
                    .frame(maxWidth: 420)

                    NumbersGridView(allNumbers: viewModel.allNumbers(), drawnNumbers: viewModel.drawnNumbers)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding()
            }
        }
    }

    private var topBarRegular: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                controlButton(titleKey: "Inicio", systemImage: "house.fill", compact: false, iconOnly: true) {
                    currentScreen = .home
                }
                controlButton(titleKey: "control.start", systemImage: "play.fill", compact: false, iconOnly: false) {
                    attemptStart()
                }
                controlButton(titleKey: "control.stop", systemImage: "pause.fill", compact: false, iconOnly: false) {
                    viewModel.stopDrawing()
                }
                controlButton(titleKey: "control.reset", systemImage: "arrow.counterclockwise", compact: false, iconOnly: false) {
                    viewModel.resetGame()
                    refreshRotatingThemeBackground()
                }

                Spacer()
            }
            HStack(spacing: 8) {
                controlButton(titleKey: "control.pdf", systemImage: "doc.fill", compact: false, iconOnly: false) {
                    generatePDF()
                }
                Spacer()
                paywallButton(compact: false)

                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gear")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .padding(.horizontal, 2)
                }
                .buttonStyle(UnifiedButtonStyle())
            }
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.black.opacity(0.75))
        }
    }

    private func topBarCompact(singleRow: Bool) -> some View {
        VStack(spacing: 6) {
            if singleRow {
                HStack(spacing: 6) {
                    controlButton(titleKey: "Inicio", systemImage: "house.fill", compact: true, iconOnly: true) {
                        currentScreen = .home
                    }
                    controlButton(titleKey: "control.start", systemImage: "play.fill", compact: true, iconOnly: true) {
                        attemptStart()
                    }
                    controlButton(titleKey: "control.stop", systemImage: "pause.fill", compact: true, iconOnly: true) {
                        viewModel.stopDrawing()
                    }
                    controlButton(titleKey: "control.reset", systemImage: "arrow.counterclockwise", compact: true, iconOnly: true) {
                        viewModel.resetGame()
                        refreshRotatingThemeBackground()
                    }
                    Spacer(minLength: 8)
                    controlButton(titleKey: "control.pdf", systemImage: "doc.fill", compact: true, iconOnly: false) {
                        generatePDF()
                    }
                    Spacer(minLength: 8)
                    paywallButton(compact: true)
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .padding(.horizontal, 2)
                    }
                    .buttonStyle(UnifiedButtonStyle(compact: true))
                }
            } else {
                HStack(spacing: 6) {
                    controlButton(titleKey: "Inicio", systemImage: "house.fill", compact: true, iconOnly: true) {
                        currentScreen = .home
                    }
                    controlButton(titleKey: "control.start", systemImage: "play.fill", compact: true, iconOnly: true) {
                        attemptStart()
                    }
                    controlButton(titleKey: "control.stop", systemImage: "pause.fill", compact: true, iconOnly: true) {
                        viewModel.stopDrawing()
                    }
                    controlButton(titleKey: "control.reset", systemImage: "arrow.counterclockwise", compact: true, iconOnly: true) {
                        viewModel.resetGame()
                        refreshRotatingThemeBackground()
                    }
                    Spacer()
                }
                HStack(spacing: 6) {
                    controlButton(titleKey: "control.pdf", systemImage: "doc.fill", compact: true, iconOnly: false) {
                        generatePDF()
                    }
                    Spacer()
                    paywallButton(compact: true)
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .padding(.horizontal, 2)
                    }
                    .buttonStyle(UnifiedButtonStyle(compact: true))
                }
            }
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(.black.opacity(0.75))
        }
    }

    private var lastNumbersCompact: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("label.last_five_numbers")
                .font(.subheadline)
                .bold()
                .foregroundStyle(.white)

            HStack(spacing: 6) {
                ForEach(Array(viewModel.drawnNumbers.suffix(5).reversed().enumerated()), id: \.element) { index, number in
                    BallView(number: number, color: ballColors[number % ballColors.count])
                        .frame(width: 34 - CGFloat(index * 2), height: 34 - CGFloat(index * 2))
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.black.opacity(0.4))
        )
    }

    private func controlButton(titleKey: LocalizedStringKey, systemImage: String, compact: Bool, iconOnly: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            if iconOnly {
                Label(titleKey, systemImage: systemImage)
                    .labelStyle(.iconOnly)
            } else {
                Label(titleKey, systemImage: systemImage)
                    .labelStyle(.titleAndIcon)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .buttonStyle(UnifiedButtonStyle(compact: compact))
    }

    private func paywallButton(compact: Bool) -> some View {
        Button {
            openPaywall()
        } label: {
            HStack(spacing: compact ? 6 : 8) {
                CoinBadgeView(credits: creditsManager.credits, isPro: purchaseManager.isPro)
                Image(systemName: purchaseManager.isPro ? "star.circle.fill" : "plus.circle.fill")
                    .font(compact ? .subheadline : .headline)
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .buttonStyle(.plain)
        .help(purchaseManager.isPro ? "Gestionar compras Pro" : "Conseguir monedas o activar Pro")
    }

    private func captionView(compact: Bool) -> some View {
        Group {
            if let caption = viewModel.currentCaption {
                Text(caption)
                    .font(compact ? .subheadline : .title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(compact ? 8 : 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.black.opacity(0.5))
                    )
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.currentCaption)
    }

    private var ballColors: [Color] {
        [.yellow, .blue, .red, .purple, .orange, .green, .black]
    }

    private var resolvedTheme: ThemeMode {
        ThemeResolver.resolvedTheme(for: Date(), mode: settings.themeMode)
    }

    private var themedBackground: some View {
        GeometryReader { geometry in
            ZStack {
                if resolvedTheme == .christmas || resolvedTheme == .lucky {
                    Image(rotatingThemeBackground)
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()

                    if resolvedTheme == .christmas {
                        VStack {
                            HStack(spacing: -100) {
                                Image(.cloud1)
                                    .resizable()
                                    .frame(width: 300, height: 300)
                                    .offset(x: 200)
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
                                    .offset(x: -100)
                            }
                            SpriteView(scene: scene, options: [.allowsTransparency])
                                .offset(y: -180)
                                .frame(minWidth: 0, maxWidth: 1000, minHeight: 0, maxHeight: geometry.size.height)
                                .ignoresSafeArea()
                        }
                        .offset(y: -geometry.size.height / 2)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    } else {
                        LinearGradient(
                            colors: [.black.opacity(0.15), .yellow.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .ignoresSafeArea()
                    }
                } else {
                    LinearGradient(
                        colors: [Color(red: 0.1, green: 0.12, blue: 0.16), Color(red: 0.2, green: 0.24, blue: 0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    RoundedRectangle(cornerRadius: 0)
                        .fill(.white.opacity(0.06))
                        .blur(radius: 30)
                        .offset(x: -120, y: -200)
                }
            }
        }
        .ignoresSafeArea()
    }

    private var scene: SKScene {
        let scene = SnowScene()
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
        return scene
    }

    private func refreshRotatingThemeBackground() {
        switch resolvedTheme {
        case .christmas:
            rotatingThemeBackground = "ChristmasBackground\(Int.random(in: 1...10))"
        case .lucky:
            rotatingThemeBackground = "LuckyBackground\(Int.random(in: 1...9))"
        default:
            rotatingThemeBackground = "ChristmasBackground1"
        }
    }

    private func openGameScreen() {
        currentScreen = .game
    }

    private func attemptStart() {
        guard !viewModel.isDrawing else { return }

        if purchaseManager.isPro || viewModel.isResumingCurrentGame {
            viewModel.startDrawing()
            return
        }

        if creditsManager.consumeForGame() {
            viewModel.startDrawing()
        } else {
            paywallReason = .insufficientCoins
            showPaywall = true
        }
    }

    private func openPaywall() {
        paywallReason = creditsManager.canAffordGame() ? .postGame : .insufficientCoins
        showPaywall = true
    }

    private func generatePDF() {
        guard let url = viewModel.generateBingoCards(maxNumber: settings.maxNumber) else { return }
        #if os(macOS)
        NSWorkspace.shared.activateFileViewerSelecting([url])
        #elseif os(iOS) || os(visionOS)
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
            activityVC.popoverPresentationController?.sourceView = rootVC.view
            activityVC.popoverPresentationController?.sourceRect = CGRect(
                x: scene.windows.first?.bounds.midX ?? 0,
                y: scene.windows.first?.bounds.midY ?? 0,
                width: 0,
                height: 0
            )
            activityVC.popoverPresentationController?.permittedArrowDirections = []
            rootVC.present(activityVC, animated: true, completion: nil)
        }
        #endif
    }
}
