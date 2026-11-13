#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AdMasterSDK/AdMasterSDK.h>
#import "ADMTopOnAnyThinkCompat.h"
#import "ADMTopOnBiddingNotice.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * TopOn (AnyThink) 开屏 (Splash) 自定义适配器
 * 同时支持常规 Waterfall 加载与 C2S Header Bidding 实时竞价
 * 包含内部容器自动清理（防幽灵遮罩拦截触摸）
 * 对标 Android: cc.admaster.android.topon.adapter.AdMasterTopOnSplashAdapter
 */
@interface ADMTopOnSplashAdapter : NSObject <ADMSplashDelegate, ADMFullScreenContentDelegate>

/// 事件回调代理（供聚合桥接、Demo 或单测监听全生命周期事件）
@property (nonatomic, weak, nullable) id <ADMTopOnAdapterEventDelegate> delegate;

/// 底层 AdMaster 开屏广告实例
@property (nonatomic, strong, readonly, nullable) ADMSplashAd *splashAd;

/// C2S 竞价通知处理器
@property (nonatomic, strong, readonly, nullable) ADMTopOnBiddingNotice *biddingNotice;

/// TopOn 标准自定义 Adapter 初始化入口
- (instancetype)initWithNetworkCustomInfo:(nullable NSDictionary *)serverExtra
                                localInfo:(nullable NSDictionary *)localExtra;

/// 常规 Waterfall 加载入口
- (void)loadADWithInfo:(NSDictionary *)serverExtra
             localInfo:(nullable NSDictionary *)localExtra
            completion:(nullable ATADLoadCompletionBlock)completion;

/// C2S Header Bidding 竞价请求入口（实例方法）
- (void)startBiddingRequestWithInfo:(NSDictionary *)serverExtra
                          localInfo:(nullable NSDictionary *)localExtra
                         completion:(ATBiddingCompletionBlock)completion;

/// C2S Header Bidding 竞价请求入口（类方法，兼容 TopOn 反射调用）
+ (void)startBiddingRequestWithInfo:(NSDictionary *)serverExtra
                          localInfo:(nullable NSDictionary *)localExtra
                         completion:(ATBiddingCompletionBlock)completion;

/// TopOn 经典 C2S 竞价类方法桥接
+ (void)bidRequestWithPlacementModel:(nullable id)placementModel
                      unitGroupModel:(nullable id)unitGroupModel
                                info:(NSDictionary *)info
                          completion:(ATBiddingCompletionBlock)completion;

/// TopOn 标准就绪检查类方法桥接
+ (BOOL)adReadyWithCustomObject:(id)customObject info:(nullable NSDictionary *)info;

/// TopOn 标准展示类方法桥接
+ (void)showSplash:(id)splash withInfo:(nullable NSDictionary *)info;

/// 广告是否已就绪且可展示
- (BOOL)isAdReady;

/// 展示开屏广告
- (void)showSplashAdInWindow:(nullable UIWindow *)window
            inViewController:(nullable UIViewController *)viewController
                   parameter:(nullable NSDictionary *)parameter;

/// TopOn 标准 C2S 竞价结果回传入口（对齐 ATBaseAdapterProtocol）
- (void)didReceiveBidResult:(ATBidWinLossResult *)result;

/// 触发 C2S 竞胜通知
- (void)notifyBidWinWithPrice:(double)price secondPrice:(double)secondPrice;

/// 触发 C2S 竞败通知
- (void)notifyBidLossWithLossType:(ATBiddingLossType)lossType winPrice:(double)winPrice;

/// 释放广告资源并清理内部容器（防幽灵遮罩）
- (void)destory;
- (void)destroy;

@end

NS_ASSUME_NONNULL_END
