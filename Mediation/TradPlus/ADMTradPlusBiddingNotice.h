//
//  ADMTradPlusBiddingNotice.h
//  TradPlusMediationAdMaster
//
//  Thread-safe, idempotent C2S Header Bidding Win/Loss notice handler.
//

#import <Foundation/Foundation.h>
#import "ADMTradPlusCompat.h"

NS_ASSUME_NONNULL_BEGIN

/// Protocol for AdMaster ad objects supporting C2S bidding win/loss notifications
@protocol ADMTradPlusBiddingNotifiable <NSObject>
- (void)biddingSuccessWithSecondInfo:(NSDictionary *)info
                          completion:(nullable void (^)(BOOL success, NSString *_Nullable errorInfo))completion;
- (void)biddingFailWithWinInfo:(NSDictionary *)info
                    completion:(nullable void (^)(BOOL success, NSString *_Nullable errorInfo))completion;
@end

@interface ADMTradPlusBiddingNotice : NSObject <ADMTradPlusBiddingNoticeProtocol>

@property (nonatomic, copy, readonly) NSString *placementID;
@property (nonatomic, copy, readonly) NSString *unitID;
@property (nonatomic, copy, readonly) NSString *adFormat;
@property (nonatomic, assign, readonly) double bidPriceCents;
@property (nonatomic, assign, readonly) BOOL hasNotifiedWin;
@property (nonatomic, assign, readonly) BOOL hasNotifiedLoss;
@property (nonatomic, assign, readonly) BOOL hasNotified;

/// Most recent win secondInfo dictionary sent to AdMaster SDK (for unit test & diagnostic verification)
@property (nonatomic, copy, readonly, nullable) NSDictionary *lastWinSecondInfo;

/// Most recent loss winInfo dictionary sent to AdMaster SDK (for unit test & diagnostic verification)
@property (nonatomic, copy, readonly, nullable) NSDictionary *lastLossWinInfo;

- (instancetype)initWithPlacementID:(NSString *)placementID
                             unitID:(NSString *)unitID
                      bidPriceCents:(double)bidPriceCents
                           adObject:(nullable id)adObject;

- (instancetype)initWithAdObject:(nullable id)adObject
                        adFormat:(NSString *)adFormat
                   bidPriceCents:(double)bidPriceCents;

- (void)notifyBidWinWithPrice:(double)winPrice
                  secondPrice:(double)secondPrice
                        extra:(nullable NSDictionary *)extra;

- (void)notifyBidLossWithLossType:(TPBiddingLossType)lossType
                         winPrice:(double)winPrice
                            extra:(nullable NSDictionary *)extra;

/// Handle TradPlus C2S Win dictionary (biddingSuccessWithSecondInfo:)
- (void)handleTradPlusWinInfo:(nullable NSDictionary *)info;

/// Handle TradPlus C2S Loss dictionary (biddingFailWithWinInfo:)
- (void)handleTradPlusLossInfo:(nullable NSDictionary *)info;

/// Map TPBiddingLossType to AdMaster loss reason code
+ (NSInteger)mapAdMasterLossReasonFromLossType:(TPBiddingLossType)lossType;

/// Parse raw TradPlus loss_reason value (number or string) into TPBiddingLossType
+ (TPBiddingLossType)parseLossReasonFromValue:(nullable id)rawValue;

@end

NS_ASSUME_NONNULL_END
