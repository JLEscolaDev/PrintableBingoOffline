import StoreKit
import SwiftUI

struct CoffeeSupportView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @EnvironmentObject private var creditsManager: CreditsManager

    @State private var isPurchasingProductID: String?
    @State private var showThanksAlert = false
    @State private var thanksMessage = ""

    private let supportProductNameKeys: [String: String] = [
        "com.printablebingo.support.coffee": "coffee.product.coffee",
        "com.printablebingo.support.breakfast": "coffee.product.breakfast",
        "com.printablebingo.support.project": "coffee.product.project"
    ]

    private func localizedName(for product: Product) -> LocalizedStringKey {
        LocalizedStringKey(supportProductNameKeys[product.id] ?? product.displayName)
    }

    private func localizedNameText(for product: Product) -> String {
        if let key = supportProductNameKeys[product.id] {
            return String(localized: String.LocalizationValue(key))
        }
        return product.displayName
    }

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 34))
                .foregroundStyle(.yellow)

            VStack(spacing: 10) {
                Text("coffee.title")
                    .font(.title2.bold())
                Text("coffee.subtitle")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 10) {
                if purchaseManager.isLoading && purchaseManager.supportProducts.isEmpty {
                    ProgressView("coffee.loading")
                } else if purchaseManager.supportProducts.isEmpty {
                    Text("coffee.products_unavailable")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    #if DEBUG
                    Text("paywall.debug_storekit_hint")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    #endif
                } else {
                    ForEach(purchaseManager.supportProducts) { product in
                        Button {
                            Task {
                                await purchase(product)
                            }
                        } label: {
                            HStack {
                                Text(localizedName(for: product))
                                Spacer()
                                if isPurchasingProductID == product.id {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Text(product.displayPrice)
                                        .fontWeight(.bold)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isPurchasingProductID != nil)
                    }
                }
            }

            if let error = purchaseManager.lastError {
                Text(error)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.red)
            }

            Text("coffee.footer")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("common.close") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding(24)
        .onAppear {
            purchaseManager.clearError()
            Task {
                await purchaseManager.refreshProducts()
            }
        }
        .alert("coffee.thanks_title", isPresented: $showThanksAlert) {
            Button("common.ok") {
                dismiss()
            }
        } message: {
            Text(thanksMessage)
        }
        #if os(macOS)
        .frame(minWidth: 420, idealWidth: 460)
        #endif
    }

    private func purchase(_ product: Product) async {
        isPurchasingProductID = product.id
        defer { isPurchasingProductID = nil }

        let didPurchase = await purchaseManager.purchase(product)
        guard didPurchase else { return }

        if purchaseManager.isPro {
            SettingsManager.shared.unlockLuckyTheme()
            thanksMessage = String(localized: "coffee.thanks_message.theme")
        } else {
            creditsManager.addBonusCredits(500)
            let format = String(localized: "coffee.thanks_message.coins", defaultValue: "Gracias por apoyar Printable Bingo Offline con %@. Como sorpresa, has recibido 500 monedas.")
            thanksMessage = String(format: format, locale: Locale.current, localizedNameText(for: product))
        }
        showThanksAlert = true
    }
}
