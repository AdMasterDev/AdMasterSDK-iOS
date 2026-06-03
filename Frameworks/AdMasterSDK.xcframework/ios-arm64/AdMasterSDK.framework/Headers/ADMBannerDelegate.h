//
//  ADMBannerDelegate.h
//  AdMasterSDK
//

#ifndef ADMBannerDelegate_h
#define ADMBannerDelegate_h

#import <Foundation/Foundation.h>
#import <AdMasterSDK/ADMError.h>

NS_ASSUME_NONNULL_BEGIN

@class ADMBannerView;

NS_SWIFT_NAME(BannerDelegate)
@protocol ADMBannerDelegate <NSObject>

@optional

- (void)bannerViewDidReceiveAd:(nonnull ADMBannerView *)bannerView NS_SWIFT_UI_ACTOR;
- (void)bannerView:(nonnull ADMBannerView *)bannerView didFailToReceiveAdWithError:(nonnull NSError *)error NS_SWIFT_UI_ACTOR;
- (void)bannerViewDidRecordImpression:(nonnull ADMBannerView *)bannerView NS_SWIFT_UI_ACTOR;
- (void)bannerView:(nonnull ADMBannerView *)bannerView didFailToDisplayAdWithError:(nonnull NSError *)error NS_SWIFT_UI_ACTOR;
- (void)bannerViewDidRecordClick:(nonnull ADMBannerView *)bannerView NS_SWIFT_UI_ACTOR;
- (void)bannerViewDidDismiss:(nonnull ADMBannerView *)bannerView NS_SWIFT_UI_ACTOR;

@end

NS_ASSUME_NONNULL_END

#endif /* ADMBannerDelegate_h */
