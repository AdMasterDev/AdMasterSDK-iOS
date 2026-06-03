//
//  ADMSplashAd.h
//  AdMasterSDK
//

#ifndef ADMSplashAd_h
#define ADMSplashAd_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AdMasterSDK/ADMFullScreenContentDelegate.h>
#import <AdMasterSDK/ADMRequest.h>
#import <AdMasterSDK/ADMResponseInfo.h>

NS_ASSUME_NONNULL_BEGIN

@class ADMSplashAd;

typedef void (^ADMSplashAdLoadCompletionHandler)(ADMSplashAd *_Nullable splashAd,
                                                 NSError *_Nullable error);

@protocol ADMSplashDelegate <NSObject>

@optional

- (void)splashAdDidReceiveAd:(ADMSplashAd *)splashAd;
- (void)splashAd:(ADMSplashAd *)splashAd didFailToReceiveAdWithError:(NSError *)error;
- (void)splashAdDidSkip:(ADMSplashAd *)splashAd;

@end

@protocol ADMSplashCardViewDelegate <NSObject>

@optional

- (void)splashCardViewDidExposure:(ADMSplashAd *)splash;
- (void)splashCardViewDidClicked:(ADMSplashAd *)splash;
- (void)splashCardViewDidClose:(ADMSplashAd *)splash;
@end

@protocol ADMSplashFocusZoomOutViewDelegate <NSObject>

@optional

- (void)splashFocusZoomOutViewDidExposure:(ADMSplashAd *)splash;
- (void)splashFocusZoomOutViewDidClicked:(ADMSplashAd *)splash;
- (void)splashFocusZoomOutViewDidClose:(ADMSplashAd *)splash;
@end

@interface ADMSplashAd : NSObject

@property (nonatomic, weak, nullable) id<ADMSplashDelegate> delegate;
@property (nonatomic, weak, nullable) id<ADMFullScreenContentDelegate> fullScreenContentDelegate;
@property (nonatomic, weak, nullable) id<ADMSplashCardViewDelegate> cardDelegate;
@property (nonatomic, weak, nullable) id<ADMSplashFocusZoomOutViewDelegate> zoomOutDelegate;
@property (nonatomic, copy) ADMRequest *request;
@property (nonatomic, assign, readonly) BOOL hasCardView;
@property (nonatomic, assign, readonly) BOOL hasZoomOutView;
@property (nonatomic, copy, readonly) NSString *publisherId;
@property (nonatomic, copy) NSString *adUnitTag;
@property (nonatomic, assign) BOOL canSplashClick;
@property (nonatomic, assign) CGSize adSize;
@property (nonatomic, weak, nullable) UIViewController *presentAdViewController;
@property (nonatomic, copy, readonly, nullable) NSString *materialType;
@property (nonatomic, assign, readonly) NSInteger videoDurationMs;
@property (nonatomic, strong, readonly, nullable) ADMResponseInfo *responseInfo;

+ (void)loadWithAdUnitTag:(NSString *)adUnitTag
                  request:(nullable ADMRequest *)request
        completionHandler:(ADMSplashAdLoadCompletionHandler)completionHandler;

- (void)load;
- (BOOL)isReady;
- (void)presentInContainerView:(UIView *)containerView
      presentingViewController:(nullable UIViewController *)viewController;
- (void)loadAndPresentInContainerView:(UIView *)containerView
             presentingViewController:(nullable UIViewController *)viewController;
- (void)loadAndPresentInKeyWindow:(nullable UIWindow *)keyWindow;
- (void)stop;
- (void)resizeLayout;

- (nullable NSString *)getExtData;
- (nullable NSString *)getECPMLevel;
- (nullable NSString *)getPECPM;
- (nullable NSString *)getBiddingToken;
/// S2S bidding phase II: load using the auction token (bid id).
- (void)loadBiddingAdWithTokenId:(NSString *)tokenId;
/// Client-side bidding phase I: load from ADM JSON returned by your bidding stack (no bid HTTP call).
- (void)loadBiddingAdWithADMData:(NSString *)admData;
- (nullable NSString *)getAdDataForKey:(NSString *)key;

- (void)biddingSuccessWithSecondInfo:(NSDictionary *)secondInfo
                          completion:(nullable void (^)(BOOL success, NSString * _Nullable errorInfo))completion;
- (void)biddingFailWithWinInfo:(NSDictionary *)winInfo
                    completion:(nullable void (^)(BOOL success, NSString * _Nullable errorInfo))completion;

@end

NS_ASSUME_NONNULL_END

#endif /* ADMSplashAd_h */
