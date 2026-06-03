import AdMasterSDK
import UIKit

final class BannerAdViewController: DemoConsoleViewController {
    private var bannerView: BannerView?
    private let sizeControl = UISegmentedControl(items: ["40", "50", "100", "150"])
    private let bannerSlot = UIView()
    private var bannerHeight: NSLayoutConstraint?
    private var selectedHeight: CGFloat = 50
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Banner"
        contentView.backgroundColor = .clear
        
        bannerSlot.translatesAutoresizingMaskIntoConstraints = false
        bannerSlot.backgroundColor = UIColor(white: 0.97, alpha: 1)
        contentView.addSubview(bannerSlot)
        
        sizeControl.translatesAutoresizingMaskIntoConstraints = false
        sizeControl.selectedSegmentIndex = 1
        sizeControl.addTarget(self, action: #selector(sizeChanged(_:)), for: .valueChanged)
        contentView.addSubview(sizeControl)
        
        let hint = UILabel()
        hint.translatesAutoresizingMaskIntoConstraints = false
        hint.text = "Banner size affects the request. Width is fixed at 320."
        hint.font = .systemFont(ofSize: 12)
        hint.textColor = UIColor(white: 0.55, alpha: 1)
        hint.numberOfLines = 0
        contentView.addSubview(hint)
        
        bannerHeight = bannerSlot.heightAnchor.constraint(equalToConstant: selectedHeight)
        bannerHeight?.isActive = true
        NSLayoutConstraint.activate([
            bannerSlot.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            bannerSlot.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bannerSlot.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            sizeControl.topAnchor.constraint(equalTo: bannerSlot.bottomAnchor, constant: 12),
            sizeControl.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            hint.topAnchor.constraint(equalTo: sizeControl.bottomAnchor, constant: 8),
            hint.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            hint.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
        pinContentBottom(to: hint, constant: 12)
        
        log("adUnitTag=\(SampleConfig.bannerAdUnitTag)")
        showButton.addTarget(self, action: #selector(showTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    
    @objc private func sizeChanged(_ sender: UISegmentedControl) {
        selectedHeight = [40, 50, 100, 150][sender.selectedSegmentIndex]
        bannerHeight?.constant = selectedHeight
        log("Banner size -> 320x\(Int(selectedHeight))")
    }
    
    @objc private func showTapped() {
        bannerView?.removeFromSuperview()
        let adSize = CGSize(width: 320, height: selectedHeight)
        let banner = BannerView(adSize: adSize, adUnitTag: SampleConfig.bannerAdUnitTag)
        banner.delegate = self
        banner.translatesAutoresizingMaskIntoConstraints = false
        bannerSlot.addSubview(banner)
        NSLayoutConstraint.activate([
            banner.topAnchor.constraint(equalTo: bannerSlot.topAnchor),
            banner.centerXAnchor.constraint(equalTo: bannerSlot.centerXAnchor),
            banner.widthAnchor.constraint(equalToConstant: adSize.width),
            banner.heightAnchor.constraint(equalToConstant: adSize.height)
        ])
        bannerView = banner
        logCall("banner.loadAd() size=\(Int(adSize.width))x\(Int(adSize.height))")
        banner.loadAd()
    }
}

// MARK: - BannerDelegate

extension BannerAdViewController: BannerDelegate {
    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        logCallback()
    }
    
    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        logError(error)
    }
    
    func bannerViewDidRecordImpression(_ bannerView: BannerView) {
        logCallback()
    }
    
    func bannerView(_ bannerView: BannerView, didFailToDisplayAdWithError error: Error) {
        logError(error)
    }
    
    func bannerViewDidRecordClick(_ bannerView: BannerView) {
        logCallback()
    }
    
    func bannerViewDidDismiss(_ bannerView: BannerView) {
        logCallback()
    }
}
