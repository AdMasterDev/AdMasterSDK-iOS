//
//  ADMTradPlusCompat.h
//  TradPlusMediationAdMaster
//
//  Compile-time compatibility bridge for TradPlus iOS SDK (<TradPlusAds/TradPlusAds.h>).
//  When TradPlusAds SDK headers are available in the host app / Pod environment,
//  it imports the official headers and extends TradPlusBaseAdapter / TradPlusAdWaterfallItem
//  with unified C2S & Waterfall helper methods. Otherwise it provides lightweight
//  protocol-accurate shims so the adapter module can be compiled and unit-tested standalone.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#if __has_include(<TradPlusAds/TradPlusAds.h>)
#define ADM_TRADPLUS_HAS_SDK 1
#import <TradPlusAds/TradPlusAds.h>
#if __has_include(<TradPlusAds/TradPlusBaseAdapter.h>)
#import <TradPlusAds/TradPlusBaseAdapter.h>
#endif
#if __has_include(<TradPlusAds/TradPlusAdWaterfallItem.h>)
#import <TradPlusAds/TradPlusAdWaterfallItem.h>
#endif
#if __has_include(<TradPlusAds/TradPlusAdRes.h>)
#import <TradPlusAds/TradPlusAdRes.h>
#endif
#else
#define ADM_TRADPLUS_HAS_SDK 0
#endif

NS_ASSUME_NONNULL_BEGIN

/// TradPlus C2S Bidding Loss Reason Codes (aligned with TradPlus & OpenRTB)
typedef NS_ENUM(NSInteger, TPBiddingLossType) {
    TPBiddingLossTypeOther = 0,
    TPBiddingLossTypeBiddingTimeOut = 101,
    TPBiddingLossTypeLowPriceInHB = 102,
    TPBiddingLossTypeLowPriceInNormal = 103,
    TPBiddingLossTypeExpire = 5
};

/// TradPlus Bidding Currency Type
typedef NS_ENUM(NSInteger, TPBiddingCurrencyType) {
    TPBiddingCurrencyTypeUSD = 0,
    TPBiddingCurrencyTypeCNY = 1
};

/// TradPlus C2S Bid Result Item
@interface TPBidInfo : NSObject

@property (nonatomic, copy, readonly) NSString *price;
@property (nonatomic, assign, readonly) double priceValue;
@property (nonatomic, copy, readonly) NSString *currency;
@property (nonatomic, assign, readonly) TPBiddingCurrencyType currencyType;
@property (nonatomic, copy, readonly, nullable) NSString *placementID;
@property (nonatomic, copy, readonly, nullable) NSString *unitGroupUnitID;
@property (nonatomic, copy, readonly, nullable) NSString *adapterClassString;
@property (nonatomic, assign, readonly) NSTimeInterval expirationInterval;
@property (nonatomic, strong, readonly, nullable) id winNotice;
@property (nonatomic, strong, readonly, nullable) id biddingNotice;
@property (nonatomic, strong, readonly, nullable) id customObject;
@property (nonatomic, copy, readonly, nullable) NSString *errorMessage;
@property (nonatomic, assign, readonly) BOOL isValid;

+ (instancetype)bidInfoWithPrice:(NSString *)price
                        currency:(nullable NSString *)currency
                       winNotice:(nullable id)winNotice
                    customObject:(nullable id)customObject;

+ (instancetype)bidInfoC2SWithPlacementID:(NSString *)placementID
                          unitGroupUnitID:(NSString *)unitGroupUnitID
                       adapterClassString:(NSString *)adapterClassString
                                    price:(NSString *)price
                             currencyType:(TPBiddingCurrencyType)currencyType
                       expirationInterval:(NSTimeInterval)expirationInterval
                             customObject:(nullable id)customObject
                            biddingNotice:(nullable id)biddingNotice;

+ (instancetype)bidInfoC2SWithErrorMessage:(NSString *)errorMessage;

@end

typedef void (^TPBiddingCompletionBlock)(TPBidInfo *_Nullable bidInfo, NSError *_Nullable error);
typedef void (^TPAdLoadCompletionBlock)(NSArray<NSDictionary *> *_Nullable assets, NSError *_Nullable error);

/// Protocol for C2S Win/Loss notification object
@protocol ADMTradPlusBiddingNoticeProtocol <NSObject>
- (void)notifyBidWinWithPrice:(double)winPrice
                  secondPrice:(double)secondPrice
                        extra:(nullable NSDictionary *)extra;
- (void)notifyBidLossWithLossType:(TPBiddingLossType)lossType
                         winPrice:(double)winPrice
                            extra:(nullable NSDictionary *)extra;
@end

/// Optional observer delegate for adapter unit/integration tests and direct mode
@protocol ADMTradPlusAdapterEventDelegate <NSObject>
@optional
- (void)tradPlusAdapterDidLoad:(id)adapter extra:(nullable NSDictionary *)extra;
- (void)tradPlusAdapterDidFinishLoad:(id)adapter;
- (void)tradPlusAdapterDidFailToLoad:(id)adapter error:(NSError *)error;
- (void)tradPlusAdapter:(id)adapter didFailToLoadWithError:(NSError *)error;
- (void)tradPlusAdapterDidShow:(id)adapter extra:(nullable NSDictionary *)extra;
- (void)tradPlusAdapterDidFailToShow:(id)adapter error:(NSError *)error;
- (void)tradPlusAdapter:(id)adapter didFailToShowWithError:(NSError *)error;
- (void)tradPlusAdapterDidClick:(id)adapter extra:(nullable NSDictionary *)extra;
- (void)tradPlusAdapterDidClose:(id)adapter extra:(nullable NSDictionary *)extra;
- (void)tradPlusAdapterDidReward:(id)adapter extra:(nullable NSDictionary *)extra;
- (void)tradPlusAdapterVideoDidStart:(id)adapter extra:(nullable NSDictionary *)extra;
- (void)tradPlusAdapterDidStartVideo:(id)adapter extra:(nullable NSDictionary *)extra;
- (void)tradPlusAdapterVideoDidEnd:(id)adapter extra:(nullable NSDictionary *)extra;
- (void)tradPlusAdapterDidFinishVideo:(id)adapter extra:(nullable NSDictionary *)extra;
@end

#if ADM_TRADPLUS_HAS_SDK

/// Category bridging unified property names onto official TradPlusAdWaterfallItem
@interface TradPlusAdWaterfallItem (ADMTradPlusCompat)

@property (nonatomic, copy, nullable) NSString *unitID;

@end

/// Category bridging unified C2S & lifecycle helpers onto official TradPlusBaseAdapter
@interface TradPlusBaseAdapter (ADMTradPlusCompat)

@property (nonatomic, strong, nullable) id customAdObj;
@property (nonatomic, strong, nullable) NSError *lastLoadError;
@property (nonatomic, strong, nullable) NSError *lastShowError;
@property (nonatomic, copy, nullable) NSString *c2sBiddingEcpm;
@property (nonatomic, copy, nullable) NSString *c2sBiddingErrorStr;

- (void)AdLoaded;
- (void)AdVideoStart;
- (void)AdVideoEnd;
- (void)finishC2SBiddingWithEcpm:(NSString *)ecpmStr;
- (void)failC2SBiddingWithErrorStr:(NSString *)errorStr;
- (void)getC2SBiddingWithWaterfallItem:(TradPlusAdWaterfallItem *)item;
- (void)biddingSuccessWithSecondInfo:(nullable NSDictionary *)info;
- (void)biddingFailWithWinInfo:(nullable NSDictionary *)info;

@end

#else

/// TradPlus Waterfall Item carrying server config & local custom map (standalone shim)
@interface TradPlusAdWaterfallItem : NSObject

@property (nonatomic, strong) NSMutableDictionary *config;
@property (nonatomic, strong) NSMutableDictionary *extraInfoDictionary;
@property (nonatomic, copy, nullable) NSDictionary *dicCustomValue;
@property (nonatomic, copy, nullable) NSString *unitID;
@property (nonatomic, copy, nullable) NSString *placementID;
@property (nonatomic, copy, nullable) NSString *adunit_id;
@property (nonatomic, copy, nullable) NSString *adsource_placement_id;
@property (nonatomic, strong, nullable) id customAdObject;
@property (nonatomic, strong, nullable) id adRes;
@property (nonatomic, assign) CGSize bannerSize;
@property (nonatomic, assign) CGSize templateRenderSize;

@end

/// TradPlus Base Adapter (standalone shim when TradPlusAds.framework is not linked)
@interface TradPlusBaseAdapter : NSObject

@property (nonatomic, strong, nullable) TradPlusAdWaterfallItem *waterfallItem;
@property (nonatomic, weak, nullable) UIViewController *rootViewController;
@property (nonatomic, strong, nullable) id customAdObj;
@property (nonatomic, assign) BOOL isAdReady;
@property (nonatomic, assign) BOOL didStartLoad;
@property (nonatomic, strong, nullable) NSError *lastLoadError;
@property (nonatomic, strong, nullable) NSError *lastShowError;
@property (nonatomic, copy, nullable) NSString *c2sBiddingEcpm;
@property (nonatomic, copy, nullable) NSString *c2sBiddingErrorStr;

- (void)loadAdWithWaterfallItem:(TradPlusAdWaterfallItem *)item;
- (void)showAdFromRootViewController:(UIViewController *)rootViewController;
- (void)showAdInWindow:(UIWindow *)window bottomView:(nullable UIView *)bottomView;
- (BOOL)isReady;
- (nullable id)getCustomObject;

/// TradPlus C2S Bidding entrypoints
- (void)getC2SBiddingWithWaterfallItem:(TradPlusAdWaterfallItem *)item;
- (void)finishC2SBiddingWithEcpm:(NSString *)ecpmStr;
- (void)failC2SBiddingWithErrorStr:(NSString *)errorStr;
- (void)biddingSuccessWithSecondInfo:(nullable NSDictionary *)info;
- (void)biddingFailWithWinInfo:(nullable NSDictionary *)info;
- (BOOL)extraActWithEvent:(NSString *)event info:(nullable NSDictionary *)info;
- (void)ADLoadExtraCallbackWithEvent:(NSString *)event info:(nullable NSDictionary *)info;
- (void)ADShowExtraCallbackWithEvent:(NSString *)event info:(nullable NSDictionary *)info;

/// TradPlus lifecycle notification hooks
- (void)AdLoadFinsh;
- (void)AdLoaded;
- (void)AdLoadFailWithError:(NSError *)error;
- (void)AdShow;
- (void)AdShowFailWithError:(NSError *)error;
- (void)AdClick;
- (void)AdDismissed;
- (void)AdClose;
- (void)AdRewardedWithInfo:(nullable NSDictionary *)info;
- (void)AdVideoStart;
- (void)AdVideoEnd;
- (void)startPlayVideo;
- (void)didFinishVideo;
- (void)bannerDidAddSubView:(UIView *)subView;
- (void)setBannerCenterWithBanner:(UIView *)banner subView:(UIView *)subView;
- (nullable UIView *)endRender:(NSDictionary *)viewInfo clickView:(NSArray *)array;
- (void)templateRender:(UIView *)subView;

@end

#endif

NS_ASSUME_NONNULL_END
