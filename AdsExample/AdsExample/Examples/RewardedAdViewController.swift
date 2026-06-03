import AdMasterSDK
import UIKit

final class RewardedAdViewController: DemoConsoleViewController {
    private var rewarded: ADMRewardedAd?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Rewarded"
        setupAd()
        showButton.addTarget(self, action: #selector(showTapped), for: .touchUpInside)
    }
    
    // MARK: - Loading
    
    private func setupAd() {
        let ad = ADMRewardedAd()
        ad.adUnitTag = SampleConfig.rewardedAdUnitTag
        ad.delegate = self
        ad.fullScreenContentDelegate = self
        rewarded = ad
        log("adUnitTag=\(ad.adUnitTag)")
    }
    
    @objc private func showTapped() {
        logCall("rewarded.load()")
        rewarded?.load()
    }
    
    // MARK: - Presentation
    
    private func presentIfReady() {
        guard let rewarded, rewarded.isReady() else {
            log("Not ready - wait for load callback")
            return
        }
        logCall("rewarded.present(from:)")
        rewarded.present(from: self)
    }
}

// MARK: - RewardedDelegate

extension RewardedAdViewController: RewardedDelegate {
    func rewardedAdDidReceive(_ ad: ADMRewardedAd) {
        logCallback()
        presentIfReady()
    }
    
    func rewardedAd(_ ad: ADMRewardedAd, didFailToReceiveAdWithError error: Error) {
        logError(error)
    }
    
    func rewardedAd(_ ad: ADMRewardedAd, userDidEarn reward: ADMReward) {
        logCallback()
    }
    
    func rewardedAd(_ ad: ADMRewardedAd, didSkipWithProgress progress: CGFloat) {
        logCallback()
    }
}

// MARK: - ADMFullScreenContentDelegate

extension RewardedAdViewController: ADMFullScreenContentDelegate {
    func adWillPresentFullScreenContent(_ ad: Any) {
        logCallback()
    }
    
    func adDidRecordImpression(_ ad: Any) {
        logCallback()
    }
    
    func adDidRecordClick(_ ad: Any) {
        logCallback()
    }
    
    func ad(_ ad: Any, didFailToPresentFullScreenContentWithError error: Error) {
        logError(error)
    }
    
    func adWillDismissFullScreenContent(_ ad: Any) {
        logCallback()
    }
    
    func adDidDismissFullScreenContent(_ ad: Any) {
        logCallback()
        setupAd()
    }
}
