//
//  ADMBannerView.h
//  AdMasterSDK
//
//  Created by AdMasterDev on 2025/6/24.
//

#import <UIKit/UIKit.h>
#import <AdMasterSDK/ADMBannerDelegate.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(BannerView)
@interface ADMBannerView : UIView

/**
 * Initialize BannerView
 * @param adSize Ad size: 320x50, 320x100, 300x250, etc.
 * @return BannerView instance
 */
- (nonnull instancetype)initWithAdSize:(CGSize)adSize;

/**
 * Initialize BannerView
 * @param adSize Ad size: 320x50, 320x100, 300x250, etc.
 * @param adUnitTag Ad unit tag, required
 * @return BannerView instance
 */
- (nonnull instancetype)initWithAdSize:(CGSize)adSize adUnitTag:(nonnull NSString *)adUnitTag;

/**
 * Set ad size: 320x50, 320x100, 300x250, etc.
 */
@property(nonatomic, assign) IBInspectable CGSize adSize;

/**
 * Set ad unit tag, required
 */
@property(nonatomic, copy, nullable) IBInspectable NSString *adUnitTag;

/**
 * Set delegate
 */
@property(nonatomic, weak, nullable) IBOutlet id<ADMBannerDelegate> delegate;

/**
 * Load ad
 */
- (void)loadAd;

/**
 * Check if the ad is available
 */
- (BOOL)isAvailable;

@end

NS_ASSUME_NONNULL_END