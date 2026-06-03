//
//  ADMRewardedAd.h
//  AdMasterSDK
//

#ifndef ADMRewardedAd_h
#define ADMRewardedAd_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AdMasterSDK/ADMFullScreenContentDelegate.h>
#import <AdMasterSDK/ADMRequest.h>
#import <AdMasterSDK/ADMReward.h>
#import <AdMasterSDK/ADMResponseInfo.h>

NS_ASSUME_NONNULL_BEGIN

@class ADMRewardedAd;

typedef void (^ADMRewardedAdLoadCompletionHandler)(ADMRewardedAd *_Nullable rewardedAd,
                                                   NSError *_Nullable error);

/// All delegate methods are called on the main thread.
NS_SWIFT_NAME(RewardedDelegate)
@protocol ADMRewardedDelegate <NSObject>

@optional

- (void)rewardedAdDidReceiveAd:(ADMRewardedAd *)ad;
- (void)rewardedAd:(ADMRewardedAd *)ad didFailToReceiveAdWithError:(NSError *)error;
- (void)rewardedAd:(ADMRewardedAd *)ad userDidEarnReward:(ADMReward *)reward;
- (void)rewardedAdDidCompleteVideo:(ADMRewardedAd *)ad;
- (void)rewardedAd:(ADMRewardedAd *)ad didSkipWithProgress:(CGFloat)progress;

@end

@interface ADMRewardedAd : NSObject

@property (nonatomic, weak, nullable) id<ADMRewardedDelegate> delegate;
@property (nonatomic, weak, nullable) id<ADMFullScreenContentDelegate> fullScreenContentDelegate;
@property (nonatomic, copy) ADMRequest *request;
@property (nonatomic, copy, readonly) NSString *publisherId;
@property (nonatomic, copy) NSString *adUnitTag;
@property (nonatomic, copy, nullable) NSString *userID;
@property (nonatomic, copy, nullable) NSString *extraInfo;
@property (nonatomic, assign) BOOL useSkipAlertView;
@property (nonatomic, strong, readonly, nullable) ADMResponseInfo *responseInfo;

+ (void)loadWithAdUnitTag:(NSString *)adUnitTag
                  request:(nullable ADMRequest *)request
        completionHandler:(ADMRewardedAdLoadCompletionHandler)completionHandler;

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

#endif /* ADMRewardedAd_h */
