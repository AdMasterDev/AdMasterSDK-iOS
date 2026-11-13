//
//  ADMTradPlusNativeAd.h
//  TradPlusMediationAdMaster
//
//  TradPlus Custom Native Ad Wrapper for AdMaster ADMNativeAdObject.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ADMTradPlusCompat.h"

#if __has_include(<AdMasterSDK/AdMasterSDK.h>)
#import <AdMasterSDK/AdMasterSDK.h>
#else
#import "ADMNativeAdLoader.h"
#import "ADMNativeAdObject.h"
#import "ADMNativeVideoView.h"
#import "ADMRequest.h"
#endif

@class ADMTradPlusNativeAdapter;

NS_ASSUME_NONNULL_BEGIN

@interface ADMTradPlusNativeAd : NSObject <ADMNativeInteractionDelegate, ADMNativeVideoViewDelegate>

@property (nonatomic, strong, readonly) ADMNativeAdObject *nativeAdObject;
@property (nonatomic, weak, readonly, nullable) ADMTradPlusNativeAdapter *adapter;

@property (nonatomic, copy, readonly, nullable) NSString *title;
@property (nonatomic, copy, readonly, nullable) NSString *mainText;
@property (nonatomic, copy, readonly, nullable) NSString *ctaText;
@property (nonatomic, copy, readonly, nullable) NSString *advertiserName;
@property (nonatomic, copy, readonly, nullable) NSString *iconImageURLString;
@property (nonatomic, copy, readonly, nullable) NSString *mainImageURLString;
@property (nonatomic, strong, readonly, nullable) NSArray<NSString *> *imageURLList;
@property (nonatomic, copy, readonly, nullable) NSString *videoURLString;
@property (nonatomic, assign, readonly) NSTimeInterval videoDuration;
@property (nonatomic, assign, readonly) CGFloat mainImageWidth;
@property (nonatomic, assign, readonly) CGFloat mainImageHeight;
@property (nonatomic, assign, readonly) CGFloat aspectRatio;
@property (nonatomic, assign, readonly) BOOL isVideoAd;
@property (nonatomic, assign, readonly) BOOL isExpressAd;
@property (nonatomic, assign, readonly) double ecpmCents;

@property (nonatomic, strong, readonly, nullable) UIView *mediaView;
@property (nonatomic, weak, readonly, nullable) UIView *registeredContainerView;

- (instancetype)initWithNativeAdObject:(ADMNativeAdObject *)nativeAdObject
                               adapter:(nullable ADMTradPlusNativeAdapter *)adapter
                           serverExtra:(nullable NSDictionary *)serverExtra
                            localExtra:(nullable NSDictionary *)localExtra;

/// Register container and clickable views for impression & click tracking
- (void)registerContainer:(UIView *)containerView
       withClickableViews:(nullable NSArray<UIView *> *)clickableViews
           viewController:(nullable UIViewController *)viewController;

/// Activate media rendering, resize, playback, and impression tracking after container is attached to superview/window
- (void)activateMediaAndImpressionIfNeeded;

/// Unregister container view
- (void)unregisterView;

/// Export standardized TradPlus native asset dictionary
- (NSDictionary *)toTradPlusAssetDictionary;

/// Destroy native ad resources
- (void)destroy;

@end

NS_ASSUME_NONNULL_END
