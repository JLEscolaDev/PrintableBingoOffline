import SwiftUI

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
import UIKit

@MainActor
final class AdManager: NSObject, ObservableObject {
    @Published var isReady: Bool = false

    private var rewardedAd: GADRewardedAd?
    private var pendingReward: (() -> Void)?
    private var pendingDismiss: (() -> Void)?

    // TODO: Replace with your production AdMob rewarded unit id
    private let adUnitID = "ca-app-pub-3940256099942544/1712485313"

    func start() {
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        loadRewarded()
    }

    func loadRewarded() {
        let request = GADRequest()
        GADRewardedAd.load(withAdUnitID: adUnitID, request: request) { [weak self] ad, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    print("Failed to load rewarded ad: \(error)")
                    self.isReady = false
                    return
                }
                self.rewardedAd = ad
                self.rewardedAd?.fullScreenContentDelegate = self
                self.isReady = true
            }
        }
    }

    func showRewarded(onReward: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        guard let rootViewController = Self.rootViewController(), let rewardedAd else {
            isReady = false
            loadRewarded()
            onDismiss()
            return
        }

        pendingReward = onReward
        pendingDismiss = onDismiss
        isReady = false
        rewardedAd.present(fromRootViewController: rootViewController) { [weak self] in
            self?.pendingReward?()
        }
    }

    private static func rootViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first { $0.activationState == .foregroundActive } as? UIWindowScene
        return windowScene?.windows.first { $0.isKeyWindow }?.rootViewController
    }
}

extension AdManager: GADFullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        Task { @MainActor in
            pendingDismiss?()
            pendingReward = nil
            pendingDismiss = nil
            loadRewarded()
        }
    }

    nonisolated func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in
            print("Failed to present rewarded ad: \(error)")
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

    func start() {}
    func loadRewarded() {}

    func showRewarded(onReward: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        onDismiss()
    }
}
#endif
