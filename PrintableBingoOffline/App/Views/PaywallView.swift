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
    @Environment(\.locale) private var locale

    let reason: PaywallReason

    @State private var isWatchingAds = false
    @State private var remainingAds: Int = 0
    #if os(macOS)
    @State private var showProOptions = true
    #else
    @State private var showProOptions = false
    #endif

    private var coinsNeeded: Int {
        max(creditsManager.costPerGame - creditsManager.credits, 0)
    }

    private var adsOfferCount: Int {
        2
    }

    private var titleKey: LocalizedStringKey {
        reason == .postGame ? "paywall.title.recharge_coins_question" : "paywall.title.need_coins"
    }

    private func localizedBundle() -> Bundle {
        let candidates = [
            locale.identifier,
            locale.language.languageCode?.identifier
        ].compactMap { $0 }

        for code in candidates {
            if let path = Bundle.main.path(forResource: code, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                return bundle
            }
        }
        return .main
    }

    private func localizedFormat(_ key: String, _ arguments: CVarArg...) -> String {
        let format = localizedBundle().localizedString(forKey: key, value: nil, table: nil)
        return String(format: format, locale: locale, arguments: arguments)
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
        let key = adsOfferCount == 1 ? "paywall.watch_ads.one" : "paywall.watch_ads.other"
        return localizedFormat(key, adsOfferCount, adsOfferCount * creditsManager.rewardPerAd)
    }

    private func purchaseFootnote(for product: Product) -> String {
        switch product.type {
        case .autoRenewable:
            return localizedBundle().localizedString(forKey: "paywall.product_type.auto_renewable", value: nil, table: nil)
        case .nonRenewable:
            return localizedBundle().localizedString(forKey: "paywall.product_type.non_renewable", value: nil, table: nil)
        case .nonConsumable:
            return localizedBundle().localizedString(forKey: "paywall.product_type.non_consumable", value: nil, table: nil)
        case .consumable:
            return localizedBundle().localizedString(forKey: "paywall.product_type.consumable", value: nil, table: nil)
        default:
            return ""
        }
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

                    VStack(spacing: 12) {
                        Text("paywall.pro_title")
                            .font(.headline)
                        Text("paywall.pro_subtitle")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if showProOptions {
                            if purchaseManager.isLoading {
                                ProgressView()
                            } else if purchaseManager.proProducts.isEmpty {
                                Text("paywall.products_unavailable")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                #if DEBUG
                                Text("paywall.debug_storekit_hint")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                #endif
                            } else {
                                ForEach(purchaseManager.proProducts) { product in
                                    Button {
                                        Task {
                                            _ = await purchaseManager.purchase(product)
                                        }
                                    } label: {
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text(product.displayName)
                                                Spacer()
                                                Text(product.displayPrice)
                                                    .fontWeight(.bold)
                                            }
                                            let footnote = purchaseFootnote(for: product)
                                            if !footnote.isEmpty {
                                                Text(footnote)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
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

                        Text("paywall.renewal_footnote")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    #if os(iOS)
                    if !purchaseManager.isPro {
                        VStack(spacing: 10) {
                            Text("paywall.recharge_with_ads")
                                .font(.headline)
                            Text("paywall.ads_free_option")
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)
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
                            .disabled(isWatchingAds || !adManager.isReady)

                            if !adManager.isReady {
                                Text("paywall.loading_ads")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }

                            if let adStatus = adManager.statusMessage, !adStatus.isEmpty {
                                Text(adStatus)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.secondary)
                            }

                            if let adError = adManager.lastLoadError, !adError.isEmpty {
                                Text(adError)
                                    .font(.footnote)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.red)
                            }

                            #if DEBUG
                            if adManager.isUsingTestAds {
                                Text("paywall.debug_test_ads")
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.secondary)
                            }
                            #endif
                        }
                        .padding(.top, 8)
                    }
                    #else
                    if !purchaseManager.isPro {
                        Text("paywall.ads_ios_only")
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                    }
                    #endif

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
            purchaseManager.clearError()
            adManager.loadRewarded()
            Task { await purchaseManager.refreshProducts() }
        }
        .onChange(of: purchaseManager.isPro) { _, isPro in
            if isPro {
                dismiss()
            }
        }
        .onChange(of: adManager.isReady) { _, isReady in
            guard isWatchingAds, remainingAds > 0, isReady else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                showNextAd()
            }
        }
        #if os(macOS)
        .frame(minWidth: 560, idealWidth: 640, minHeight: 520, idealHeight: 620)
        #endif
    }

    private func startAutoAds() {
        remainingAds = adsOfferCount
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
