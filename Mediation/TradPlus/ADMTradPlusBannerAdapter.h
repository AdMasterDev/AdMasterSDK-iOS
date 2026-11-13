//
//  ADMTradPlusBannerAdapter.h
//  TradPlusMediationAdMaster
//
//  TradPlus Custom Banner Adapter for AdMaster iOS SDK.
//  Supports both Waterfall and C2S Header Bidding with C2S cached ad reuse.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ADMTradPlusCompat.h"
#import "ADMTradPlusBiddingNotice.h"

#if __has_include(<AdMasterSDK/AdMasterSDK.h>)
#import <AdMasterSDK/AdMasterSDK.h>
#else
#import "ADMBannerView.h"
#import "ADMBannerDelegate.h"
#import "ADMRequest.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface ADMTradPlusBannerAdapter : TradPlusBaseAdapter <ADMBannerDelegate>

@property (nonatomic, weak, nullable) id <ADMTradPlusAdapterEventDelegate> delegate;
@property (nonatomic, strong, readonly, nullable) ADMBannerView *bannerView;
@property (nonatomic, strong, readonly, nullable) ADMTradPlusBiddingNotice *biddingNotice;
@property (nonatomic, copy, readonly, nullable) NSDictionary *serverExtra;
@property (nonatomic, copy, readonly, nullable) NSDictionary *localExtra;

- (instancetype)initWithServerExtra:(nullable NSDictionary *)serverExtra
                         localExtra:(nullable NSDictionary *)localExtra;

/// Load Banner Ad (Direct / Dictionary entrypoint)
- (void)loadADWithInfo:(NSDictionary *)serverExtra
             localInfo:(nullable NSDictionary *)localExtra
            completion:(nullable TPAdLoadCompletionBlock)completion;

/// Execute C2S Header Bidding (Instance method)
- (void)startBiddingRequestWithInfo:(NSDictionary *)serverExtra
                          localInfo:(nullable NSDictionary *)localExtra
                         completion:(TPBiddingCompletionBlock)completion;

/// Execute C2S Header Bidding (Class method)
+ (void)startBiddingRequestWithInfo:(NSDictionary *)serverExtra
                          localInfo:(nullable NSDictionary *)localExtra
                         completion:(TPBiddingCompletionBlock)completion;

/// Check whether Banner Ad is loaded and ready
- (BOOL)isAdReady;

/// Notify Win (Direct entrypoint)
- (void)notifyBidWinWithPrice:(double)winPrice secondPrice:(double)secondPrice;

/// Notify Loss (Direct entrypoint)
- (void)notifyBidLossWithLossType:(TPBiddingLossType)lossType winPrice:(double)winPrice;

/// Destroy adapter resources
- (void)destroy;
- (void)destory;

@end

/// Class alias matching TradPlus dashboard naming convention
@interface TradPlusAdMasterBannerAdapter : ADMTradPlusBannerAdapter
@end

NS_ASSUME_NONNULL_END
