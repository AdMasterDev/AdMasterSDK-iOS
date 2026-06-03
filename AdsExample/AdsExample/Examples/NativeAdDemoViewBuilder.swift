import AdMasterSDK
import UIKit

final class NativeAdDemoViewBuilder {
    private weak var videoDelegate: ADMNativeVideoViewDelegate?
    private weak var closeTarget: AnyObject?
    private let closeAction: Selector?
    
    init(videoDelegate: ADMNativeVideoViewDelegate?, closeTarget: AnyObject?, closeAction: Selector?) {
        self.videoDelegate = videoDelegate
        self.closeTarget = closeTarget
        self.closeAction = closeAction
    }
    
    func build(frame: CGRect, object: ADMNativeAdObject) -> ADMNativeAdView? {
        let horizontalInset: CGFloat = 15
        let mediaAspectRatio = object.aspectRatio > 0 ? CGFloat(object.aspectRatio) : 16.0 / 9.0
        
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        
        let textLabel = UILabel()
        textLabel.font = .systemFont(ofSize: 12)
        textLabel.numberOfLines = 2
        if object.text.isEmpty {
            object.text = "Sample ad description"
        }
        
        let iconImageView = UIImageView()
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.clipsToBounds = true
        
        let mainImageView = UIImageView()
        mainImageView.contentMode = .scaleAspectFill
        mainImageView.clipsToBounds = true
        
        let brandLabel = UILabel()
        brandLabel.font = .systemFont(ofSize: 13)
        brandLabel.textColor = .gray
        
        let logoView = UIImageView()
        let actionButton = ADMAdActButton()
        
        let nativeView: ADMNativeAdView?
        let mediaView: UIView
        var morePicViews: [UIImageView] = []
        if object.materialType == VIDEO {
            guard let videoView = ADMNativeVideoView(frame: .zero, andObject: object) else {
                return nil
            }
            videoView.videoDelegate = videoDelegate
            mediaView = videoView
            nativeView = ADMNativeAdView(frame: frame, brandName: brandLabel, title: titleLabel, text: textLabel, icon: iconImageView, videoView: videoView)
        } else {
            let morePics = NSMutableArray()
            if let pics = object.morepics, pics.count > 0 {
                for _ in pics {
                    let imageView = UIImageView()
                    imageView.contentMode = .scaleAspectFill
                    imageView.clipsToBounds = true
                    morePics.add(imageView)
                    morePicViews.append(imageView)
                }
            }
            mediaView = morePicViews.isEmpty ? mainImageView : morePicViews[0]
            nativeView = ADMNativeAdView(frame: frame, brandName: brandLabel, title: titleLabel, text: textLabel, icon: iconImageView, mainImage: mainImageView, morepics: morePics)
        }
        
        guard let nativeView else { return nil }
        let closeButton = UIButton(type: .custom)
        closeButton.setImage(closeImage(), for: [])
        closeButton.imageView?.contentMode = .scaleAspectFit
        if let closeAction {
            closeButton.addTarget(closeTarget, action: closeAction, for: .touchUpInside)
        }
        
        nativeView.backgroundColor = .white
        nativeView.admLogoImageView = logoView
        nativeView.addSubview(logoView)
        nativeView.actButton = actionButton
        nativeView.addSubview(actionButton)
        nativeView.closeButton = closeButton
        nativeView.addSubview(closeButton)
        
        applyConstraints(
            in: nativeView,
            titleLabel: titleLabel,
            textLabel: textLabel,
            iconImageView: iconImageView,
            mediaView: mediaView,
            mainImageView: mainImageView,
            morePicViews: morePicViews,
            mediaAspectRatio: mediaAspectRatio,
            brandLabel: brandLabel,
            logoView: logoView,
            actionButton: actionButton,
            closeButton: closeButton,
            horizontalInset: horizontalInset
        )
        return nativeView
    }
    
    private func applyConstraints(
        in nativeView: ADMNativeAdView,
        titleLabel: UILabel,
        textLabel: UILabel,
        iconImageView: UIImageView,
        mediaView: UIView,
        mainImageView: UIImageView,
        morePicViews: [UIImageView],
        mediaAspectRatio: CGFloat,
        brandLabel: UILabel,
        logoView: UIImageView,
        actionButton: ADMAdActButton,
        closeButton: UIButton,
        horizontalInset: CGFloat
    ) {
        var constrainedViews: [UIView] = [
            titleLabel,
            textLabel,
            iconImageView,
            mediaView,
            brandLabel,
            logoView,
            actionButton,
            closeButton
        ] + morePicViews.filter { $0 !== mediaView }
        if morePicViews.isEmpty {
            constrainedViews.append(mainImageView)
        }
        constrainedViews.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        brandLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        var constraints: [NSLayoutConstraint] = [
            iconImageView.topAnchor.constraint(equalTo: nativeView.topAnchor, constant: 15),
            iconImageView.leadingAnchor.constraint(equalTo: nativeView.leadingAnchor, constant: horizontalInset),
            iconImageView.widthAnchor.constraint(equalToConstant: 60),
            iconImageView.heightAnchor.constraint(equalTo: iconImageView.widthAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: nativeView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -10),
            
            textLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            textLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            textLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            closeButton.topAnchor.constraint(equalTo: nativeView.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: nativeView.trailingAnchor, constant: -18),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalTo: closeButton.widthAnchor),
            
            brandLabel.leadingAnchor.constraint(equalTo: nativeView.leadingAnchor, constant: horizontalInset),
            brandLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 96),
            
            logoView.leadingAnchor.constraint(equalTo: brandLabel.trailingAnchor, constant: 8),
            logoView.centerYAnchor.constraint(equalTo: brandLabel.centerYAnchor),
            logoView.widthAnchor.constraint(equalToConstant: 39),
            logoView.heightAnchor.constraint(equalToConstant: 14),
            logoView.trailingAnchor.constraint(lessThanOrEqualTo: actionButton.leadingAnchor, constant: -8),
            
            actionButton.centerYAnchor.constraint(equalTo: brandLabel.centerYAnchor),
            actionButton.trailingAnchor.constraint(equalTo: nativeView.trailingAnchor, constant: -horizontalInset),
            actionButton.widthAnchor.constraint(equalToConstant: 100),
            actionButton.heightAnchor.constraint(equalToConstant: 30)
        ]
        
        if morePicViews.isEmpty {
            constraints += [
                mediaView.topAnchor.constraint(equalTo: nativeView.topAnchor, constant: 85),
                mediaView.leadingAnchor.constraint(equalTo: nativeView.leadingAnchor, constant: horizontalInset),
                mediaView.trailingAnchor.constraint(equalTo: nativeView.trailingAnchor, constant: -horizontalInset),
                brandLabel.topAnchor.constraint(equalTo: mediaView.bottomAnchor, constant: 20),
                mediaView.heightAnchor.constraint(equalTo: mediaView.widthAnchor, multiplier: 1 / mediaAspectRatio)
            ]
        } else {
            mainImageView.isHidden = true
            
            guard let firstImageView = morePicViews.first else {
                NSLayoutConstraint.activate(constraints)
                return
            }
            
            constraints += [
                firstImageView.topAnchor.constraint(equalTo: nativeView.topAnchor, constant: 85),
                firstImageView.leadingAnchor.constraint(equalTo: nativeView.leadingAnchor, constant: horizontalInset),
                firstImageView.heightAnchor.constraint(equalTo: firstImageView.widthAnchor, multiplier: 2 / 3),
                brandLabel.topAnchor.constraint(equalTo: firstImageView.bottomAnchor, constant: 20)
            ]
            
            for (index, imageView) in morePicViews.enumerated() {
                if index > 0 {
                    let previousView = morePicViews[index - 1]
                    constraints += [
                        imageView.topAnchor.constraint(equalTo: firstImageView.topAnchor),
                        imageView.bottomAnchor.constraint(equalTo: firstImageView.bottomAnchor),
                        imageView.leadingAnchor.constraint(equalTo: previousView.trailingAnchor, constant: 5),
                        imageView.widthAnchor.constraint(equalTo: previousView.widthAnchor)
                    ]
                }
                
                if index == morePicViews.count - 1 {
                    constraints.append(imageView.trailingAnchor.constraint(equalTo: nativeView.trailingAnchor, constant: -horizontalInset))
                }
            }
        }
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func closeImage() -> UIImage? {
        guard let path = Bundle.main.path(forResource: "AdMasterSDKRes", ofType: "bundle"),
              let bundle = Bundle(path: path),
              let imagePath = bundle.path(forResource: "adm_black_close", ofType: "png") else {
            return nil
        }
        return UIImage(contentsOfFile: imagePath)
    }
}
