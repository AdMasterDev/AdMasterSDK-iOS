#import "ADMTopOnBiddingNotice.h"
#import "ADMTopOnUtils.h"
#import <math.h>

@interface ADMTopOnBiddingNotice ()

@property (nonatomic, strong, nullable) id adObject;
@property (nonatomic, copy, readwrite) NSString *adFormat;
@property (nonatomic, assign, readwrite) double bidPriceCents;
@property (nonatomic, copy, readwrite, nullable) NSDictionary *lastWinSecondInfo;
@property (nonatomic, copy, readwrite, nullable) NSDictionary *lastLossWinInfo;

@end

@implementation ADMTopOnBiddingNotice

- (instancetype)initWithAdObject:(nullable id)adObject
                        adFormat:(NSString *)adFormat
                   bidPriceCents:(double)bidPriceCents {
    self = [super init];
    if (self) {
        _adObject = adObject;
        BOOL hasValidFormat = [adFormat isKindOfClass:[NSString class]] && adFormat.length > 0;
        _adFormat = hasValidFormat ? [adFormat copy] : @"Unknown";
        _bidPriceCents = (isfinite(bidPriceCents) && bidPriceCents >= 0.0) ? bidPriceCents : 0.0;
    }
    return self;
}

+ (NSInteger)mapAdMasterLossReasonFromLossType:(ATBiddingLossType)lossType {
    switch ((NSInteger)lossType) {
        case 103: // ATBiddingLossWithLowPriceInNormal
            return 103;
        case 102: // ATBiddingLossWithLowPriceInHB
            return 102;
        case 2:   // ATBiddingLossWithBiddingTimeOut
            return 2;
        case 5:   // ATBiddingLossWithExpire
            return 5;
        default:
            return 102;
    }
}

- (void)notifyBidWinWithPrice:(double)price
                  secondPrice:(double)secondPrice
                        extra:(nullable NSDictionary<NSString *, id> *)extra {
    (void)price;
    (void)extra;
    double safeSecondPrice = (isfinite(secondPrice) && secondPrice >= 0.0) ? secondPrice : 0.0;
    NSInteger secondPriceCents = (NSInteger)llround(safeSecondPrice);
    NSDictionary *secondInfo = @{
        @"ecpm": [NSString stringWithFormat:@"%ld", (long)secondPriceCents],
        @"min_to_win": @(secondPriceCents)
    };
    self.lastWinSecondInfo = secondInfo;

    id target = self.adObject;
    [ADMTopOnUtils dispatchOnMainThread:^{
        if ([target respondsToSelector:@selector(biddingSuccessWithSecondInfo:completion:)]) {
            [(id <ADMBiddingNotifiable>)target biddingSuccessWithSecondInfo:secondInfo completion:nil];
        }
    }];
}

- (void)notifyBidLossWithLossType:(ATBiddingLossType)lossType
                         winPrice:(double)winPrice
                            extra:(nullable NSDictionary<NSString *, id> *)extra {
    (void)extra;
    double safeWinPrice = (isfinite(winPrice) && winPrice >= 0.0) ? winPrice : 0.0;
    NSInteger winPriceCents = (NSInteger)llround(safeWinPrice);
    NSInteger reasonCode = [[self class] mapAdMasterLossReasonFromLossType:lossType];
    NSDictionary *winInfo = @{
        @"ecpm": [NSString stringWithFormat:@"%ld", (long)winPriceCents],
        @"min_to_win": @(winPriceCents),
        @"reason": @(reasonCode)
    };
    self.lastLossWinInfo = winInfo;

    id target = self.adObject;
    dispatch_block_t invalidateHandler = self.lossInvalidateHandler;
    self.lossInvalidateHandler = nil;
    [ADMTopOnUtils dispatchOnMainThread:^{
        if ([target respondsToSelector:@selector(biddingFailWithWinInfo:completion:)]) {
            [(id <ADMBiddingNotifiable>)target biddingFailWithWinInfo:winInfo completion:nil];
        }
        if (invalidateHandler) {
            invalidateHandler();
        }
    }];
}

@end
