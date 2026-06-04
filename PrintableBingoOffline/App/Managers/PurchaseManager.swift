import StoreKit
import SwiftUI

@MainActor
final class PurchaseManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var isPro: Bool = false
    @Published var isLoading: Bool = false
    @Published var lastError: String? = nil

    private let proProductIDs: [String] = [
        "com.printablebingo.pro.weekly",
        "com.printablebingo.pro.monthly",
        "com.printablebingo.pro.lifetime"
    ]
    private let supportProductIDs: [String] = [
        "com.printablebingo.support.coffee",
        "com.printablebingo.support.breakfast",
        "com.printablebingo.support.project"
    ]

    private var updatesTask: Task<Void, Never>?

    var proProducts: [Product] {
        products.filter { proProductIDs.contains($0.id) }
    }

    var supportProducts: [Product] {
        products.filter { supportProductIDs.contains($0.id) }
    }

    init() {
        updatesTask = Task {
            await listenForUpdates()
        }
        Task {
            await updateEntitlements()
            await refreshProducts()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    func refreshProducts() async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }
        do {
            let productIDs = proProductIDs + supportProductIDs
            let storeProducts = try await Product.products(for: productIDs)
            products = storeProducts.sorted { lhs, rhs in
                productIDs.firstIndex(of: lhs.id) ?? 0 < productIDs.firstIndex(of: rhs.id) ?? 0
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    func purchase(_ product: Product) async -> Bool {
        lastError = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await updateEntitlements()
                return true
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            lastError = error.localizedDescription
        }
        return false
    }

    func restorePurchases() async {
        lastError = nil
        do {
            try await AppStore.sync()
            await updateEntitlements()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func clearError() {
        lastError = nil
    }

    private func updateEntitlements() async {
        var hasPro = false
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if proProductIDs.contains(transaction.productID) {
                    hasPro = true
                }
            } catch {
                continue
            }
        }
        isPro = hasPro
    }

    private func listenForUpdates() async {
        for await result in Transaction.updates {
            do {
                let transaction = try checkVerified(result)
                if proProductIDs.contains(transaction.productID) {
                    await updateEntitlements()
                }
                await transaction.finish()
            } catch {
                continue
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
}
