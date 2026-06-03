import AdMasterSDK
import UIKit

final class AppOpenSplashManager: NSObject {
    static let shared = AppOpenSplashManager()
    
    private var splashAd: ADMSplashAd?
    private weak var window: UIWindow?
    private var overlay: UIView?
    private var fallbackTimer: Timer?
    
    func loadAndShow(in window: UIWindow?) {
        guard let window else { return }
        self.window = window
        
        let splash = ADMSplashAd()
        splash.delegate = self
        splash.fullScreenContentDelegate = self
        splash.adUnitTag = SampleConfig.splashAdUnitTag
        splash.adSize = window.bounds.size
        splashAd = splash
        showOverlayIfNeeded()
        startFallbackTimer()
        splash.load()
    }
    
    private func presentIfReady() {
        guard let window else {
            cleanup()
            return
        }
        guard let splashAd, splashAd.isReady() else { return }
        fallbackTimer?.invalidate()
        fallbackTimer = nil
        showOverlayIfNeeded()
        guard let overlay else { return }
        splashAd.present(inContainerView: overlay, presenting: window.rootViewController)
    }
    
    private func showOverlayIfNeeded() {
        guard overlay == nil, let window else { return }
        let overlay = UIView(frame: window.bounds)
        overlay.backgroundColor = .white
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        window.addSubview(overlay)
        self.overlay = overlay
    }
    
    private func startFallbackTimer() {
        fallbackTimer?.invalidate()
        fallbackTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
            self?.cleanup()
        }
    }
    
    private func cleanup() {
        fallbackTimer?.invalidate()
        fallbackTimer = nil
        overlay?.removeFromSuperview()
        overlay = nil
        splashAd?.stop()
        splashAd?.delegate = nil
        splashAd?.fullScreenContentDelegate = nil
        splashAd = nil
    }
}

// MARK: - ADMSplashDelegate

extension AppOpenSplashManager: ADMSplashDelegate {
    func splashAdDidReceive(_ splashAd: ADMSplashAd) {
        presentIfReady()
    }
    
    func splashAd(_ splashAd: ADMSplashAd, didFailToReceiveAdWithError error: Error) {
        cleanup()
    }
    
    func splashAdDidSkip(_ splashAd: ADMSplashAd) {
        cleanup()
    }
}

// MARK: - ADMFullScreenContentDelegate

extension AppOpenSplashManager: ADMFullScreenContentDelegate {
    func ad(_ ad: Any, didFailToPresentFullScreenContentWithError error: Error) {
        cleanup()
    }
    
    func adDidDismissFullScreenContent(_ ad: Any) {
        cleanup()
    }
}
