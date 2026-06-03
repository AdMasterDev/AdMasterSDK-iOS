//
//  ADMNativeAdObject.h
//  AdMasterSDK
//
//  Created by lishan04 on 15-5-26.
//  Copyright (c) 2015  lishan04. All rights reserved.
//

#ifndef ADMNativeAdObject_h
#define ADMNativeAdObject_h

#import <Foundation/Foundation.h>
#import <AdMasterSDK/ADMCommonConfig.h>
#import <AdMasterSDK/ADMNativeInteractionDelegate.h>

NS_ASSUME_NONNULL_BEGIN

@interface ADMNativeAdObject : NSObject

/**
 * Interaction delegate.
 */
@property (nonatomic, weak) id<ADMNativeInteractionDelegate> interactionDelegate;

/**
 * Title text.
 */
@property (copy, nonatomic) NSString *title;
/**
 * Description text.
 */
@property (copy, nonatomic) NSString *text;
/**
 * Icon image URL.
 */
@property (copy, nonatomic) NSString *iconImageURLString;
/**
 * Main image URL.
 */
@property (copy, nonatomic) NSString *mainImageURLString;

/**
 * Multi-image native ad URLs.
 */
@property (nullable, strong, nonatomic) NSArray *morepics;
/**
 * Video URL.
 */
@property (copy, nonatomic) NSString *videoURLString;
/**
 * Video duration in seconds.
 */
@property (strong, nonatomic) NSNumber *videoDuration;
/**
 * Autoplay flag.
 */
@property (strong, nonatomic) NSNumber *autoPlay;
/**
 * Brand name (empty if not returned).
 */
@property (copy, nonatomic) NSString *brandName;
/**
 * After enabling video in your integration, check ADMMaterialType before choosing a renderer.
 */
@property (assign, nonatomic) ADMMaterialType materialType;

/**
 * Click action type for this ad unit.
 */
@property (assign, nonatomic) ADMNativeAdActionType actType;

/**
 * Main image width.
 */
@property (assign, nonatomic) float w;
/**
 * Main image height.
 */
@property (assign, nonatomic) float h;

/**
 * Main image aspect ratio.
 */
@property (assign, nonatomic) float aspectRatio;

/**
 * Price tier label.
 */
@property (copy, nonatomic, readonly) NSString *ECPMLevel;

/**
 * CTA label for user click action.
 */
@property (copy, nonatomic) NSString *actButtonString;

#pragma mark - Express / smart layout
/**
 * Native ad container width.
 */
@property (nonatomic, assign) int container_width;
/**
 * Native ad container height.
 */
@property (nonatomic, assign) int container_height;

/**
 * View controller to present landing page (overrides ADMNative setting).
 */
- (void)setPresentAdViewController:(UIViewController *)presentAdViewController;

/**
 * Report dislike / negative feedback to ``interactionDelegate``.
 */
- (void)reportDislikeWithReasonCode:(NSInteger)reasonCode;

/**
 * Price tier label (eCPM level).
 */
- (NSString *)getECPMLevel;

- (NSString *)getPECPM;

/**
 * Report bidding win and send second-place loser info.
 * @param secondInfo Second-place loser info
 *        Key: ecpm  Value: second-place bid in cents (Integer). Optional
 *        Key: adn   Value: second-place ADN channel ID (Integer). See docs for enum values
 * @param completion Callback when send succeeds or fails
 */
- (void)biddingSuccessWithSecondInfo:(NSDictionary *)secondInfo
                          completion:(void (^)(BOOL success, NSString *errorInfo))completion;

/**
 * Report bidding loss with reason; may report winner info when no ad fill.
 * @param winInfo Winner info
 *        Key: ecpm  Value: winning bid in cents (Integer). Optional
 *        Key: adn   Value: winner ADN channel ID (Integer). See docs for enum values
 * @param completion Callback when send succeeds or fails
 */
- (void)biddingFailWithWinInfo:(NSDictionary *)winInfo
                    completion:(void (^)(BOOL success, NSString *errorInfo))completion;

/**
 * Whether the ad expired (default valid 2h; request again if expired).
 */
- (BOOL)isExpired;

/**
 * Ad network logo tap handler.
 */
- (void)admLogoClick:(UIView *)admLogoView;

/**
 * Ad field by key.
 * @param key Field name
 * @return String value
 */
- (NSString *)getAdDataForKey:(NSString *)key;

/**
 * Load image asset with SDK cache.
 * The SDK returns cached image data first. If no cache exists, it downloads the
 * image, stores it in cache, and then calls completion on main thread.
 *
 * @param URLString Image URL string.
 * @param completion Main-thread callback. image is nil when URL is empty,
 *        invalid, download fails, or data cannot be decoded as UIImage.
 */
- (void)loadImageWithURLString:(nullable NSString *)URLString
                    completion:(nullable void (^)(UIImage * _Nullable image))completion;

/**
 * Register views for click and impression tracking.
 * @param containerView Container view
 * @param mediaView Video or image view
 * @param clickableViews Tappable views
 * @param viewController View controller for landing page
 */
 - (void)registerViewForInteraction:(UIView *)containerView
                          mediaView:(UIView *)mediaView
                     clickableViews:(NSArray<UIView *> *)clickableViews
                     viewController:(UIViewController *)viewController;
/**
 * Unregister interaction for the container view.
 * @param view Container view
 */
- (void)unregisterView:(UIView *)view;
@end

NS_ASSUME_NONNULL_END

#endif /* ADMNativeAdObject_h */
