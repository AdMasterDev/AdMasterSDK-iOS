import AdMasterSDK
import UIKit

final class InterstitialAdViewController: DemoConsoleViewController {
    private var interstitial: ADMInterstitialAd?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Interstitial"
        setupAd()
        showButton.addTarget(self, action: #selector(showTapped), for: .touchUpInside)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let tag = size.width > size.height ? SampleConfig.interstitialAdUnitTagLandscape : SampleConfig.interstitialAdUnitTagPortrait
        interstitial?.adUnitTag = tag
        log("adUnitTag -> \(tag)")
    }
    
    // MARK: - Loading
    
    private func setupAd() {
        let ad = ADMInterstitialAd()
        ad.adUnitTag = SampleConfig.interstitialAdUnitTagPortrait
        ad.delegate = self
        ad.fullScreenContentDelegate = self
        interstitial = ad
        log("adUnitTag=\(ad.adUnitTag)")
    }
    
    @objc private func showTapped() {
        logCall("interstitial.load()")
        interstitial?.load()
    }
    
    // MARK: - Presentation
    
    private func presentIfReady() {
        guard let interstitial, interstitial.isReady() else {
            log("Not ready - wait for load callback")
            return
        }
        logCall("interstitial.present(from:)")
        interstitial.present(from: self)
    }
}

// MARK: - InterstitialDelegate

extension InterstitialAdViewController: InterstitialDelegate {
    func interstitialAdDidReceive(_ ad: ADMInterstitialAd) {
        logCallback()
        presentIfReady()
    }
    
    func interstitialAd(_ ad: ADMInterstitialAd, didFailToReceiveAdWithError error: Error) {
        logError(error)
    }
}

// MARK: - ADMFullScreenContentDelegate

extension InterstitialAdViewController: ADMFullScreenContentDelegate {
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
