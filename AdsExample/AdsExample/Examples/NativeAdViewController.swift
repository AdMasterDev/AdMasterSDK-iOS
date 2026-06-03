import AdMasterSDK
import UIKit

final class NativeAdViewController: DemoConsoleViewController {
    private let adContainerView = UIView()
    private var adContainerHeight: NSLayoutConstraint?
    private var nativeLoader: ADMNativeAdLoader?
    private var currentAdView: ADMNativeAdView?
    private var currentAdObject: ADMNativeAdObject?
    private lazy var nativeAdViewBuilder = NativeAdDemoViewBuilder(videoDelegate: self, closeTarget: self, closeAction: #selector(closeAd))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Native"
        contentView.backgroundColor = .clear
        
        adContainerView.translatesAutoresizingMaskIntoConstraints = false
        adContainerView.backgroundColor = UIColor(white: 0.97, alpha: 1)
        adContainerView.clipsToBounds = true
        contentView.addSubview(adContainerView)
        
        adContainerHeight = adContainerView.heightAnchor.constraint(equalToConstant: placeholderHeight())
        adContainerHeight?.isActive = true
        NSLayoutConstraint.activate([
            adContainerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            adContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            adContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
        pinContentBottom(to: adContainerView)
        
        log("adUnitTag=\(SampleConfig.nativeAdUnitTag)")
        showButton.addTarget(self, action: #selector(showTapped), for: .touchUpInside)
    }
    
    // MARK: - Layout
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if currentAdView == nil {
            adContainerHeight?.constant = placeholderHeight()
        }
    }
    
    @objc private func showTapped() {
        clearCurrentAd()
        loadNativeAd()
    }
    
    private func previewWidth() -> CGFloat {
        let width = view.bounds.width
        return width > 0 ? width : UIScreen.main.bounds.width
    }
    
    private func placeholderHeight() -> CGFloat {
        nativePreviewHeight(width: previewWidth(), aspectRatio: 0)
    }
    
    private func previewHeight(for object: ADMNativeAdObject) -> CGFloat {
        nativePreviewHeight(width: previewWidth(), aspectRatio: CGFloat(object.aspectRatio))
    }
    
    private func nativePreviewHeight(width: CGFloat, aspectRatio: CGFloat) -> CGFloat {
        if aspectRatio > 0 {
            return (width - 30) / aspectRatio + 130
        }
        return (width - 30) * 9 / 16 + 130
    }
    
    // MARK: - Loading
    
    private func loadNativeAd() {
        if nativeLoader == nil {
            nativeLoader = ADMNativeAdLoader()
            nativeLoader?.delegate = self
        }
        nativeLoader?.adUnitTag = SampleConfig.nativeAdUnitTag
        nativeLoader?.presentAdViewController = self
        
        logCall("nativeLoader.load() adUnitTag=\(SampleConfig.nativeAdUnitTag)")
        nativeLoader?.load()
    }
    
    // MARK: - Rendering
    
    private func clearCurrentAd() {
        currentAdObject?.unregisterView(currentAdView ?? adContainerView)
        currentAdView?.removeFromSuperview()
        currentAdView = nil
        currentAdObject = nil
        adContainerHeight?.constant = placeholderHeight()
    }
    
    private func display(object: ADMNativeAdObject) {
        let width = previewWidth()
        let height = previewHeight(for: object)
        guard let adView = nativeAdViewBuilder.build(frame: CGRect(x: 0, y: 0, width: width, height: height), object: object) else {
            logFailure("Failed to build native ad view")
            return
        }
        
        clearCurrentAd()
        currentAdObject = object
        currentAdView = adView
        adContainerHeight?.constant = height
        
        adView.translatesAutoresizingMaskIntoConstraints = false
        adContainerView.addSubview(adView)
        NSLayoutConstraint.activate([
            adView.topAnchor.constraint(equalTo: adContainerView.topAnchor),
            adView.leadingAnchor.constraint(equalTo: adContainerView.leadingAnchor),
            adView.trailingAnchor.constraint(equalTo: adContainerView.trailingAnchor),
            adView.bottomAnchor.constraint(equalTo: adContainerView.bottomAnchor)
        ])
        
        object.interactionDelegate = self
        logCall("adView.loadAndDisplayNativeAd(with:)")
        adView.loadAndDisplayNativeAd(with: object) { [weak self, weak adView] errors in
            guard let self, let adView else { return }
            if let errors, errors.count > 0 {
                self.logFailure("loadAndDisplay errors=\(errors)")
                return
            }
            guard adView === self.currentAdView else { return }
            self.log("Displayed native ad title=\(object.title) size=\(Int(width))x\(Int(height))")
        }
    }
    
    @objc private func closeAd() {
        clearCurrentAd()
        log("Removed native ad")
    }
}

// MARK: - ADMNativeAdLoaderDelegate

extension NativeAdViewController: ADMNativeAdLoaderDelegate, ADMNativeInteractionDelegate {
    func nativeAdLoader(_ loader: ADMNativeAdLoader, didReceiveNativeAds ads: [ADMNativeAdObject]) {
        logCallback()
        guard let object = ads.first(where: { !$0.isExpired() }) else {
            logFailure("No valid non-expired native ad in response")
            return
        }
        display(object: object)
    }
    
    func nativeAdLoader(_ loader: ADMNativeAdLoader, didFailToReceiveAdWithError error: Error, nativeAdObject adObject: ADMNativeAdObject?) {
        logError(error)
    }
    
    // MARK: ADMNativeInteractionDelegate
    
    func nativeAd(_ ad: ADMNativeAdObject, didRecordImpressionFor view: UIView) {
        logCallback()
    }
    
    func nativeAd(_ ad: ADMNativeAdObject, didFailToRecordImpressionFor view: UIView, error: Error) {
        logError(error)
    }
    
    func nativeAd(_ ad: ADMNativeAdObject, didRecordClickFor view: UIView) {
        logCallback()
    }
    
    func nativeAd(_ ad: ADMNativeAdObject, didDismissLandingPageFrom view: UIView) {
        logCallback()
    }
}

// MARK: - ADMNativeVideoViewDelegate

extension NativeAdViewController: ADMNativeVideoViewDelegate {
    func nativeVideoAdDidStartPlaying(_ videoView: ADMNativeVideoView) {
        logCallback()
    }
    
    func nativeVideoAdDidComplete(_ videoView: ADMNativeVideoView) {
        logCallback()
    }
    
    func nativeVideoAdDidFailed(_ videoView: ADMNativeVideoView) {
        logCallback()
    }
    
    func nativeVideoAdDidReplay(_ videoView: ADMNativeVideoView) {
        logCallback()
    }
    
    func nativeVideoAdDidPause(_ videoView: ADMNativeVideoView) {
        logCallback()
    }
}
