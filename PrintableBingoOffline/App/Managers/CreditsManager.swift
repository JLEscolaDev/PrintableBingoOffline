//
//  CreditsManager.swift
//  PrintableBingoOffline
//
//  Created by Jose Luis Escolá García on 31/12/24.
//


import SwiftUI

@MainActor
class CreditsManager: ObservableObject {
    let initialCredits = 100
    let costPerGame = 49
    let rewardPerAd = 25
    let maxCredits = 200

    @Published var credits: Int {
        didSet {
            UserDefaults.standard.set(credits, forKey: "userCredits")
        }
    }

    init() {
        if UserDefaults.standard.object(forKey: "userCredits") == nil {
            self.credits = initialCredits
        } else {
            self.credits = min(UserDefaults.standard.integer(forKey: "userCredits"), maxCredits)
        }
    }

    func canAffordGame() -> Bool {
        credits >= costPerGame
    }

    @discardableResult
    func consumeForGame() -> Bool {
        guard canAffordGame() else { return false }
        credits = max(credits - costPerGame, 0)
        return true
    }

    func addReward() {
        credits = min(credits + rewardPerAd, maxCredits)
    }
}

import SwiftUI
import WebKit

#if os(iOS)
struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
#elseif os(macOS)
struct WebView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
#endif
