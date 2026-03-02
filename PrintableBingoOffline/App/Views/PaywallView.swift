import StoreKit
import SwiftUI

enum PaywallReason {
    case insufficientCoins
    case postGame
}

struct PaywallView: View {
    @EnvironmentObject private var creditsManager: CreditsManager
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @EnvironmentObject private var adManager: AdManager
    @Environment(\.dismiss) private var dismiss

    let reason: PaywallReason

    @State private var isWatchingAds = false
    @State private var remainingAds: Int = 0
    @State private var showProOptions = false

    private var coinsNeeded: Int {
        max(creditsManager.costPerGame - creditsManager.credits, 0)
    }

    private var adsNeeded: Int {
        guard coinsNeeded > 0 else { return 0 }
        let base = Int(ceil(Double(coinsNeeded) / Double(creditsManager.rewardPerAd)))
        return min(3, max(2, base))
    }

    private var titleKey: LocalizedStringKey {
        reason == .postGame ? "paywall.title.recharge_coins_question" : "paywall.title.need_coins"
    }

    private func localizedFormat(_ key: String, _ arguments: CVarArg...) -> String {
        let format = NSLocalizedString(key, comment: "")
        return String(format: format, locale: Locale.current, arguments: arguments)
    }

    private var missingCoinsText: String {
        let key = coinsNeeded == 1 ? "paywall.missing_coins.one" : "paywall.missing_coins.other"
        return localizedFormat(key, coinsNeeded)
    }

    private var watchingAdsText: String {
        let key = remainingAds == 1 ? "paywall.watching_ads.one" : "paywall.watching_ads.other"
        return localizedFormat(key, remainingAds)
    }

    private var watchAdsButtonText: String {
        let key = adsNeeded == 1 ? "paywall.watch_ads.one" : "paywall.watch_ads.other"
        return localizedFormat(key, adsNeeded, adsNeeded * creditsManager.rewardPerAd)
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text(titleKey)
                            .font(.title2)
                            .fontWeight(.bold)
                        if !purchaseManager.isPro {
                            if coinsNeeded > 0 {
                                Text(missingCoinsText)
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("paywall.has_enough_coins")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Text("paywall.pro_active")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    CoinBadgeView(credits: creditsManager.credits, isPro: purchaseManager.isPro)

                    #if os(iOS)
                    if !purchaseManager.isPro && adsNeeded > 0 {
                        VStack(spacing: 10) {
                            Text("paywall.recharge_with_ads")
                                .font(.headline)
                            Button {
                                startAutoAds()
                            } label: {
                                if isWatchingAds {
                                    HStack(spacing: 8) {
                                        ProgressView()
                                        Text(watchingAdsText)
                                    }
                                } else {
                                    Text(watchAdsButtonText)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isWatchingAds || !adManager.isReady || adsNeeded == 0)

                            if !adManager.isReady {
                                Text("paywall.loading_ads")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.top, 8)
                    }
                    #else
                    if !purchaseManager.isPro {
                        Text("paywall.ads_ios_only")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                    }
                    #endif

                    Divider()

                    VStack(spacing: 12) {
                        Text("paywall.pro_title")
                            .font(.headline)
                        Text("paywall.pro_subtitle")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if showProOptions {
                            if purchaseManager.isLoading {
                                ProgressView()
                            } else if purchaseManager.products.isEmpty {
                                Text("paywall.products_unavailable")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                #if DEBUG
                                Text("paywall.debug_storekit_hint")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                #endif
                            } else {
                                ForEach(purchaseManager.products) { product in
                                    Button {
                                        Task {
                                            await purchaseManager.purchase(product)
                                        }
                                    } label: {
                                        HStack {
                                            Text(product.displayName)
                                            Spacer()
                                            Text(product.displayPrice)
                                                .fontWeight(.bold)
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .disabled(purchaseManager.isPro)
                                }
                            }

                            Button("paywall.restore_purchases") {
                                Task { await purchaseManager.restorePurchases() }
                            }
                            .font(.footnote)
                        } else {
                            Button("paywall.show_pro_options") {
                                showProOptions = true
                                Task { await purchaseManager.refreshProducts() }
                            }
                            .buttonStyle(.bordered)
                        }

                        if let error = purchaseManager.lastError {
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }
                    }

                    #if DEBUG
                    Button("paywall.debug_add_100_coins") {
                        for _ in 0..<4 {
                            creditsManager.addReward()
                        }
                    }
                    .buttonStyle(.bordered)
                    #endif

                    Button("common.close") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .top)
                .frame(minHeight: geometry.size.height, alignment: .top)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .onAppear {
            adManager.loadRewarded()
        }
        .onChange(of: purchaseManager.isPro) { _, isPro in
            if isPro {
                dismiss()
            }
        }
    }

    private func startAutoAds() {
        guard adsNeeded > 0 else { return }
        remainingAds = adsNeeded
        isWatchingAds = true
        showNextAd()
    }

    private func showNextAd() {
        guard remainingAds > 0 else {
            isWatchingAds = false
            return
        }
        guard adManager.isReady else {
            adManager.loadRewarded()
            isWatchingAds = false
            return
        }

        remainingAds -= 1
        adManager.showRewarded(onReward: {
            creditsManager.addReward()
        }, onDismiss: {
            if remainingAds > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showNextAd()
                }
            } else {
                isWatchingAds = false
            }
        })
    }
}
