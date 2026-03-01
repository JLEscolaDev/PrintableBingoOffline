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

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text(reason == .postGame ? "¿Quieres recargar monedas?" : "Necesitas monedas")
                    .font(.title2)
                    .fontWeight(.bold)
                if !purchaseManager.isPro {
                    if coinsNeeded > 0 {
                        Text("Te faltan \(coinsNeeded) monedas para jugar otra partida.")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Tienes suficientes monedas para otra partida.")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Tienes Pro activo. Puedes jugar sin límites.")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }

            CoinBadgeView(credits: creditsManager.credits, isPro: purchaseManager.isPro)

            #if os(iOS)
            if !purchaseManager.isPro && adsNeeded > 0 {
                VStack(spacing: 10) {
                    Text("Recargar con anuncios")
                        .font(.headline)
                    Button {
                        startAutoAds()
                    } label: {
                        if isWatchingAds {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("Viendo anuncios... (quedan \(remainingAds))")
                            }
                        } else {
                            Text("Ver \(adsNeeded) anuncios (+\(adsNeeded * creditsManager.rewardPerAd))")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isWatchingAds || !adManager.isReady || adsNeeded == 0)

                    if !adManager.isReady {
                        Text("Cargando anuncios...")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 8)
            }
            #else
            if !purchaseManager.isPro {
                Text("Los anuncios solo están disponibles en iOS.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
            }
            #endif

            Divider()

            VStack(spacing: 12) {
                Text("Bingo Pro")
                    .font(.headline)
                Text("Sin anuncios, sin monedas y acceso completo.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if showProOptions {
                    if purchaseManager.isLoading {
                        ProgressView()
                    } else if purchaseManager.products.isEmpty {
                        Text("Productos no disponibles en este momento.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        #if DEBUG
                        Text("En simulador usa StoreKit config. En dispositivo necesitas App Store Connect + sandbox tester.")
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

                    Button("Restaurar compras") {
                        Task { await purchaseManager.restorePurchases() }
                    }
                    .font(.footnote)
                } else {
                    Button("Ver opciones Pro") {
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

            Spacer()

            #if DEBUG
            Button("Añadir 100 monedas (debug)") {
                for _ in 0..<4 {
                    creditsManager.addReward()
                }
            }
            .buttonStyle(.bordered)
            #endif

            Button("Cerrar") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding()
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
