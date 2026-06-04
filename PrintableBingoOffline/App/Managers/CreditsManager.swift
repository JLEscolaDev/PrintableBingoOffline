//
//  CreditsManager.swift
//  PrintableBingoOffline
//
//  Created by Jose Luis Escolá García on 31/12/24.
//

import Foundation
import SwiftUI

@MainActor
class CreditsManager: ObservableObject {
    #if os(macOS)
    let initialCredits = 250
    #else
    let initialCredits = 100
    #endif
    let maxCredits = 999
    let costPerGame = 49
    let rewardPerAd = 25

    private let creditsKey = "userCredits"
    #if os(macOS)
    private let macInitialGrantKey = "macOSInitialCreditsGranted"
    private let cloudStore = NSUbiquitousKeyValueStore.default
    private var externalChangeObserver: NSObjectProtocol?
    #endif

    @Published var credits: Int {
        didSet {
            persistCredits(credits)
        }
    }

    init() {
        #if os(macOS)
        cloudStore.synchronize()

        let resolvedCredits: Int
        if cloudStore.object(forKey: macInitialGrantKey) == nil {
            resolvedCredits = initialCredits
            cloudStore.set(true, forKey: macInitialGrantKey)
            cloudStore.set(initialCredits, forKey: creditsKey)
            cloudStore.synchronize()
            UserDefaults.standard.set(true, forKey: macInitialGrantKey)
        } else if cloudStore.object(forKey: creditsKey) != nil {
            resolvedCredits = min(Int(clamping: cloudStore.longLong(forKey: creditsKey)), maxCredits)
        } else if UserDefaults.standard.object(forKey: creditsKey) != nil {
            resolvedCredits = min(UserDefaults.standard.integer(forKey: creditsKey), maxCredits)
            cloudStore.set(resolvedCredits, forKey: creditsKey)
            cloudStore.synchronize()
        } else {
            resolvedCredits = initialCredits
            cloudStore.set(initialCredits, forKey: creditsKey)
            cloudStore.set(true, forKey: macInitialGrantKey)
            cloudStore.synchronize()
            UserDefaults.standard.set(true, forKey: macInitialGrantKey)
        }

        self.credits = resolvedCredits
        UserDefaults.standard.set(resolvedCredits, forKey: creditsKey)
        observeCloudChanges()
        #else
        if UserDefaults.standard.object(forKey: creditsKey) == nil {
            self.credits = initialCredits
        } else {
            self.credits = min(UserDefaults.standard.integer(forKey: creditsKey), maxCredits)
        }
        #endif
    }

    deinit {
        #if os(macOS)
        if let externalChangeObserver {
            NotificationCenter.default.removeObserver(externalChangeObserver)
        }
        #endif
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

    func addBonusCredits(_ amount: Int) {
        guard amount > 0 else { return }
        credits = min(credits + amount, maxCredits)
    }

    private func persistCredits(_ value: Int) {
        let clampedValue = min(value, maxCredits)
        UserDefaults.standard.set(clampedValue, forKey: creditsKey)

        #if os(macOS)
        cloudStore.set(clampedValue, forKey: creditsKey)
        cloudStore.set(true, forKey: macInitialGrantKey)
        #endif
    }

    #if os(macOS)
    private func observeCloudChanges() {
        externalChangeObserver = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloudStore,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            guard let changedKeys = notification.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String],
                  changedKeys.contains(self.creditsKey),
                  self.cloudStore.object(forKey: self.creditsKey) != nil else {
                return
            }

            let syncedCredits = min(Int(clamping: self.cloudStore.longLong(forKey: self.creditsKey)), self.maxCredits)
            if self.credits != syncedCredits {
                self.credits = syncedCredits
            }
        }
    }
    #endif
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
