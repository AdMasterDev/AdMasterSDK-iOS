//
//  ADMBannerDelegate.h
//  AdMasterSDK
//
//  Created by AdMasterDev on 2025/6/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ADMBannerView;

NS_SWIFT_NAME(BannerDelegate)
@protocol ADMBannerDelegate <NSObject>

@optional

/**
 * Ad loaded successfully
 */
- (void)bannerViewDidLoadAd:(nonnull ADMBannerView *)bannerView NS_SWIFT_UI_ACTOR;

/**
 * Ad failed to load
 */
- (void)bannerView:(nonnull ADMBannerView *)bannerView didFailToLoadAdWithError:(nonnull NSError *)error NS_SWIFT_UI_ACTOR;

/**
 * Ad impression successful
 */
- (void)bannerViewDidImpression:(nonnull ADMBannerView *)bannerView NS_SWIFT_UI_ACTOR;

/**
 * Ad display failed
 */
- (void)bannerView:(nonnull ADMBannerView *)bannerView didFailToDisplayAdWithError:(nonnull NSError *)error NS_SWIFT_UI_ACTOR;

/**
 * Ad clicked
 */
- (void)bannerViewDidClick:(nonnull ADMBannerView *)bannerView NS_SWIFT_UI_ACTOR;

/**
 * Ad closed
 */
- (void)bannerViewDidClose:(nonnull ADMBannerView *)bannerView NS_SWIFT_UI_ACTOR;

@end

NS_ASSUME_NONNULL_END