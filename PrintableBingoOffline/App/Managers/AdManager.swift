import SwiftUI

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
import UIKit

@MainActor
final class AdManager: NSObject, ObservableObject {
    @Published var isReady: Bool = false
    @Published var lastLoadError: String?
    @Published var statusMessage: String?

    private var rewardedAd: GADRewardedAd?
    private var pendingReward: (() -> Void)?
    private var pendingDismiss: (() -> Void)?

    #if DEBUG
    private let adUnitID = "ca-app-pub-3940256099942544/1712485313"
    let isUsingTestAds = true
    #else
    private let adUnitID = "ca-app-pub-6739983890245057/2394185157"
    let isUsingTestAds = false
    #endif

    func start() {
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        statusMessage = isUsingTestAds
            ? String(localized: "ad.status.test_active")
            : String(localized: "ad.status.loading_many")
        loadRewarded()
    }

    func loadRewarded() {
        lastLoadError = nil
        statusMessage = String(localized: "ad.status.loading_one")
        let request = GADRequest()
        GADRewardedAd.load(withAdUnitID: adUnitID, request: request) { [weak self] ad, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    print("Failed to load rewarded ad: \(error)")
                    self.isReady = false
                    self.lastLoadError = error.localizedDescription
                    self.statusMessage = String(localized: "ad.status.load_failed")
                    return
                }
                self.rewardedAd = ad
                self.rewardedAd?.fullScreenContentDelegate = self
                self.isReady = true
                self.lastLoadError = nil
                self.statusMessage = String(localized: "ad.status.ready")
            }
        }
    }

    func showRewarded(onReward: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        guard let rootViewController = Self.rootViewController(), let rewardedAd else {
            isReady = false
            lastLoadError = String(localized: "ad.error.no_presenter")
            statusMessage = String(localized: "ad.status.no_presenter")
            loadRewarded()
            onDismiss()
            return
        }

        pendingReward = onReward
        pendingDismiss = onDismiss
        isReady = false
        statusMessage = String(localized: "ad.status.presenting")
        rewardedAd.present(fromRootViewController: rootViewController) { [weak self] in
            self?.pendingReward?()
        }
    }

    private static func rootViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first { $0.activationState == .foregroundActive } as? UIWindowScene
        guard let root = windowScene?.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }
        return topViewController(from: root)
    }

    private static func topViewController(from root: UIViewController) -> UIViewController {
        if let presented = root.presentedViewController {
            return topViewController(from: presented)
        }
        if let navigation = root as? UINavigationController,
           let visible = navigation.visibleViewController {
            return topViewController(from: visible)
        }
        if let tab = root as? UITabBarController,
           let selected = tab.selectedViewController {
            return topViewController(from: selected)
        }
        return root
    }
}

extension AdManager: GADFullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        Task { @MainActor in
            statusMessage = String(localized: "ad.status.dismissed")
            pendingDismiss?()
            pendingReward = nil
            pendingDismiss = nil
            loadRewarded()
        }
    }

    nonisolated func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in
            print("Failed to present rewarded ad: \(error)")
            lastLoadError = error.localizedDescription
            statusMessage = String(localized: "ad.status.present_failed")
            pendingDismiss?()
            pendingReward = nil
            pendingDismiss = nil
            loadRewarded()
        }
    }
}
#else
@MainActor
final class AdManager: ObservableObject {
    @Published var isReady: Bool = false
    @Published var lastLoadError: String?
    @Published var statusMessage: String?
    let isUsingTestAds = false

    func start() {}
    func loadRewarded() {}

    func showRewarded(onReward: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        onDismiss()
    }
}
#endif
