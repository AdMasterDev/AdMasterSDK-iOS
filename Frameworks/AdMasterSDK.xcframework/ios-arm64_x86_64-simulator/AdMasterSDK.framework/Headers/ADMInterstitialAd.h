//
//  ADMInterstitialAd.h
//  AdMasterSDK
//

#ifndef ADMInterstitialAd_h
#define ADMInterstitialAd_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AdMasterSDK/ADMFullScreenContentDelegate.h>
#import <AdMasterSDK/ADMRequest.h>
#import <AdMasterSDK/ADMResponseInfo.h>

NS_ASSUME_NONNULL_BEGIN

@class ADMInterstitialAd;

typedef void (^ADMInterstitialAdLoadCompletionHandler)(ADMInterstitialAd *_Nullable interstitialAd,
                                                       NSError *_Nullable error);

/// Load-phase callbacks only. For presentation events use ``ADMFullScreenContentDelegate`` on ``fullScreenContentDelegate``. All methods are called on the main thread.
NS_SWIFT_NAME(InterstitialDelegate)
@protocol ADMInterstitialDelegate <NSObject>

@optional

- (void)interstitialAdDidReceiveAd:(ADMInterstitialAd *)ad;
- (void)interstitialAd:(ADMInterstitialAd *)ad didFailToReceiveAdWithError:(NSError *)error;
- (void)interstitialAd:(ADMInterstitialAd *)ad didRecordDislikeFeedback:(NSDictionary *)info;

@end

@interface ADMInterstitialAd : NSObject

@property (nonatomic, weak, nullable) id<ADMInterstitialDelegate> delegate;
@property (nonatomic, weak, nullable) id<ADMFullScreenContentDelegate> fullScreenContentDelegate;
@property (nonatomic, copy) ADMRequest *request;
@property (nonatomic, copy, readonly) NSString *publisherId;
@property (nonatomic, copy) NSString *adUnitTag;
@property (nonatomic, strong, readonly, nullable) ADMResponseInfo *responseInfo;

+ (void)loadWithAdUnitTag:(NSString *)adUnitTag
                  request:(nullable ADMRequest *)request
        completionHandler:(ADMInterstitialAdLoadCompletionHandler)completionHandler;

- (void)load;
- (BOOL)isReady;
- (void)presentFromRootViewController;
- (void)presentFromViewController:(UIViewController *)viewController;

- (nullable NSString *)getECPMLevel;
- (nullable NSString *)getPECPM;
- (nullable NSString *)getBiddingToken;
- (void)loadBiddingAdWithTokenId:(NSString *)tokenId;
- (void)loadBiddingAdWithADMData:(NSString *)admData;
- (nullable NSString *)getAdDataForKey:(NSString *)key;

- (void)biddingSuccessWithSecondInfo:(NSDictionary *)secondInfo
                          completion:(void (^)(BOOL success, NSString * _Nullable errorInfo))completion;
- (void)biddingFailWithWinInfo:(NSDictionary *)winInfo
                    completion:(void (^)(BOOL success, NSString * _Nullable errorInfo))completion;

@end

NS_ASSUME_NONNULL_END

#endif /* ADMInterstitialAd_h */
