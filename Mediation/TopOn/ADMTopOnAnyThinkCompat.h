#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#if __has_include(<AnyThinkSDK/AnyThinkSDK.h>)
#import <AnyThinkSDK/AnyThinkSDK.h>
#define ADM_TOPON_HAS_ANYTHINK_SDK 1
#define ADM_TOPON_BIDDING_CURRENCY_CNY_CENTS ((ATBiddingCurrencyType)3)
#else
#define ADM_TOPON_HAS_ANYTHINK_SDK 0

NS_ASSUME_NONNULL_BEGIN

/**
 * TopOn (AnyThink) C2S 竞败原因枚举兼容定义（当宿主未通过 CocoaPods 引入 AnyThinkiOS 时供单测与 Demo 编译使用）
 */
typedef NS_ENUM(NSInteger, ATBiddingLossType) {
    ATBiddingLossWithLowPriceInNormal = 103,
    ATBiddingLossWithLowPriceInHB = 102,
    ATBiddingLossWithBiddingTimeOut = 2,
    ATBiddingLossWithExpire = 5,
    ATBiddingLossWithFloorFilter = 104,
    ATBiddingLossWithKSClickOrShow = 8
};

/**
 * TopOn 币种类型兼容定义（对齐 ATAdEnums.h）
 */
typedef NS_ENUM(NSInteger, ATBiddingCurrencyType) {
    ATBiddingCurrencyTypeUS = 1,
    ATBiddingCurrencyTypeCNY = 2,
    ATBiddingCurrencyTypeCNYCents = 3
};
#define ADM_TOPON_BIDDING_CURRENCY_CNY_CENTS ATBiddingCurrencyTypeCNYCents

/**
 * TopOn C2S 竞价结果回传类型兼容定义（对齐 ATBidWinLossResult.h）
 */
typedef NS_ENUM(NSInteger, ATBidWinLossResultType) {
    ATBidWinLossResultTypeWin = 0,
    ATBidWinLossResultTypeLoss = 1
};

@interface ATBidWinLossResult : NSObject

@property (nonatomic, assign) ATBidWinLossResultType bidResultType;
@property (nonatomic, assign) ATBiddingLossType lossReasonType;
@property (nonatomic, strong, nullable) NSString *winPrice;
@property (nonatomic, strong, nullable) NSString *secondPrice;
@property (nonatomic, strong, nullable) NSDictionary *userInfoDic;

@end

/**
 * TopOn C2S 竞价结果模型兼容声明（对齐 ATBidInfo.h）
 */
@interface ATBidInfo : NSObject

@property (nonatomic, copy, readonly) NSString *placementID;
@property (nonatomic, copy, readonly) NSString *unitID;
@property (nonatomic, copy, readonly) NSString *adapterClassString;
@property (nonatomic, copy, readonly) NSString *price;
@property (nonatomic, assign, readonly) ATBiddingCurrencyType currencyType;
@property (nonatomic, strong, readonly, nullable) id customObject;
@property (nonatomic, assign, readonly, getter=isValid) BOOL valid;

+ (instancetype)bidInfoC2SWithPlacementID:(NSString *)placementID
                          unitGroupUnitID:(NSString *)unitGroupUnitID
                       adapterClassString:(NSString *)adapterClassString
                                    price:(NSString *)price
                             currencyType:(ATBiddingCurrencyType)currencyType
                       expirationInterval:(NSTimeInterval)expirationInterval
                             customObject:(nullable id)customObject;

@end

typedef void (^ATADLoadCompletionBlock)(NSArray<NSDictionary *> *_Nullable completionArray, NSError *_Nullable error);

NS_ASSUME_NONNULL_END

#endif

NS_ASSUME_NONNULL_BEGIN

typedef void (^ATBiddingCompletionBlock)(ATBidInfo *_Nullable bidInfo, NSError *_Nullable error);

/**
 * TopOn 自定义 Adapter 事件回调协议（供单测、Demo 与聚合桥接监听全生命周期事件）
 */
@protocol ADMTopOnAdapterEventDelegate <NSObject>
@optional
- (void)topOnAdapterDidLoad:(id)adapter extra:(nullable NSDictionary *)extra;
- (void)topOnAdapterDidFailToLoad:(id)adapter error:(NSError *)error;
- (void)topOnAdapterDidShow:(id)adapter extra:(nullable NSDictionary *)extra;
- (void)topOnAdapterDidFailToShow:(id)adapter error:(NSError *)error;
- (void)topOnAdapterDidClick:(id)adapter extra:(nullable NSDictionary *)extra;
- (void)topOnAdapterDidClose:(id)adapter extra:(nullable NSDictionary *)extra;
- (void)topOnAdapterDidReward:(id)adapter extra:(nullable NSDictionary *)extra;
- (void)topOnAdapterVideoDidStart:(id)adapter extra:(nullable NSDictionary *)extra;
- (void)topOnAdapterVideoDidEnd:(id)adapter extra:(nullable NSDictionary *)extra;
@end

NS_ASSUME_NONNULL_END
