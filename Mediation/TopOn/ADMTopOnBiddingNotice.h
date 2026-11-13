#import <Foundation/Foundation.h>
#import "ADMTopOnAnyThinkCompat.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 声明支持竞价胜败通知的 AdMaster 广告对象协议
 * ADMBannerView / ADMInterstitialAd / ADMRewardedAd / ADMSplashAd / ADMNativeAdObject 均实现了这两个方法
 */
@protocol ADMBiddingNotifiable <NSObject>
- (void)biddingSuccessWithSecondInfo:(NSDictionary *)info completion:(void (^_Nullable)(NSError *_Nullable error))completion;
- (void)biddingFailWithWinInfo:(NSDictionary *)info completion:(void (^_Nullable)(NSError *_Nullable error))completion;
@end

/**
 * TopOn C2S Header Bidding 竞胜/竞败通知处理器
 * 对标 Android: cc.admaster.android.topon.adapter.AdMasterTopOnBiddingNotice
 */
@interface ADMTopOnBiddingNotice : NSObject

/// 当前广告形式标识（如 @"RewardedVideo", @"Interstitial", @"Banner", @"Splash", @"Native"）
@property (nonatomic, copy, readonly) NSString *adFormat;

/// 本次竞价报价（单位：分）
@property (nonatomic, assign, readonly) double bidPriceCents;

/// 最近一次触发的竞胜二价参数（供单测与诊断核验）
@property (nonatomic, copy, readonly, nullable) NSDictionary *lastWinSecondInfo;

/// 最近一次触发的竞败参数（供单测与诊断核验）
@property (nonatomic, copy, readonly, nullable) NSDictionary *lastLossWinInfo;

/// 竞败时的缓存清理回调（供 C2S 缓存池自动回收未展示的竞败广告）
@property (nonatomic, copy, nullable) dispatch_block_t lossInvalidateHandler;

- (instancetype)initWithAdObject:(nullable id)adObject
                        adFormat:(NSString *)adFormat
                   bidPriceCents:(double)bidPriceCents;

/// 将 TopOn ATBiddingLossType 映射为 AdMaster 竞败原因码（103 / 102 / 2 / 5）
+ (NSInteger)mapAdMasterLossReasonFromLossType:(ATBiddingLossType)lossType;

/// 触发竞胜通知（支持直接调用或通过 ATAdBiddingNoticeProtocol 回调）
- (void)notifyBidWinWithPrice:(double)price
                  secondPrice:(double)secondPrice
                        extra:(nullable NSDictionary<NSString *, id> *)extra;

/// 触发竞败通知（支持直接调用或通过 ATAdBiddingNoticeProtocol 回调）
- (void)notifyBidLossWithLossType:(ATBiddingLossType)lossType
                         winPrice:(double)winPrice
                            extra:(nullable NSDictionary<NSString *, id> *)extra;

@end

NS_ASSUME_NONNULL_END
