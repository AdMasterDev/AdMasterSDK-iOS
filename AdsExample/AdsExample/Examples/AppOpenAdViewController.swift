import AdMasterSDK
import UIKit

final class AppOpenAdViewController: DemoConsoleViewController {
    private var splashAd: ADMSplashAd?
    private var overlay: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "App Open"
        setupAd()
        showButton.addTarget(self, action: #selector(showTapped), for: .touchUpInside)
    }
    
    // MARK: - Loading
    
    private func setupAd() {
        let splash = ADMSplashAd()
        splash.delegate = self
        splash.fullScreenContentDelegate = self
        splash.adUnitTag = SampleConfig.splashAdUnitTag
        splash.adSize = view.window?.bounds.size ?? UIScreen.main.bounds.size
        splashAd = splash
        log("adUnitTag=\(splash.adUnitTag) adSize=\(Int(splash.adSize.width))x\(Int(splash.adSize.height))")
    }
    
    @objc private func showTapped() {
        removeOverlay()
        logCall("splashAd.load()")
        splashAd?.load()
    }
    
    // MARK: - Presentation
    
    private func presentIfReady() {
        guard let splashAd, splashAd.isReady() else {
            log("Not ready - wait for splashAdDidReceiveAd")
            return
        }
        guard let window = view.window else {
            logFailure("No window for splash container")
            return
        }
        let overlay = UIView(frame: window.bounds)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.backgroundColor = .white
        window.addSubview(overlay)
        self.overlay = overlay
        logCall("splashAd.present(inContainerView:presenting:)")
        splashAd.present(inContainerView: overlay, presenting: self)
    }
    
    private func removeOverlay() {
        overlay?.removeFromSuperview()
        overlay = nil
    }
}

// MARK: - ADMSplashDelegate

extension AppOpenAdViewController: ADMSplashDelegate {
    func splashAdDidReceive(_ splashAd: ADMSplashAd) {
        logCallback()
        presentIfReady()
    }
    
    func splashAd(_ splashAd: ADMSplashAd, didFailToReceiveAdWithError error: Error) {
        logError(error)
        removeOverlay()
    }
}

// MARK: - ADMFullScreenContentDelegate

extension AppOpenAdViewController: ADMFullScreenContentDelegate {
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
        removeOverlay()
    }
    
    func adWillDismissFullScreenContent(_ ad: Any) {
        logCallback()
    }
    
    func adDidDismissFullScreenContent(_ ad: Any) {
        logCallback()
        removeOverlay()
        setupAd()
    }
}
