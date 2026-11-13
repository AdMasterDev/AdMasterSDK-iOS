//
//  ADMTradPlusBiddingNotice.m
//  TradPlusMediationAdMaster
//

#import "ADMTradPlusBiddingNotice.h"
#import "ADMTradPlusConstants.h"
#import "ADMTradPlusUtils.h"
#import <math.h>

@interface ADMTradPlusBiddingNotice ()

@property (nonatomic, copy, readwrite) NSString *placementID;
@property (nonatomic, copy, readwrite) NSString *unitID;
@property (nonatomic, copy, readwrite) NSString *adFormat;
@property (nonatomic, assign, readwrite) double bidPriceCents;
@property (nonatomic, assign, readwrite) BOOL hasNotifiedWin;
@property (nonatomic, assign, readwrite) BOOL hasNotifiedLoss;
@property (nonatomic, assign, readwrite) BOOL hasNotified;
@property (nonatomic, copy, readwrite, nullable) NSDictionary *lastWinSecondInfo;
@property (nonatomic, copy, readwrite, nullable) NSDictionary *lastLossWinInfo;
@property (nonatomic, strong, nullable) id adObject;

@end

@implementation ADMTradPlusBiddingNotice

- (instancetype)initWithPlacementID:(NSString *)placementID
                             unitID:(NSString *)unitID
                      bidPriceCents:(double)bidPriceCents
                           adObject:(id)adObject {
    self = [super init];
    if (self) {
        _placementID = [placementID copy] ?: @"";
        _unitID = [unitID copy] ?: @"";
        _adFormat = @"Unknown";
        _bidPriceCents = (isfinite(bidPriceCents) && bidPriceCents > 0.0) ? bidPriceCents : 0.0;
        _adObject = adObject;
    }
    return self;
}

- (instancetype)initWithAdObject:(id)adObject
                        adFormat:(NSString *)adFormat
                   bidPriceCents:(double)bidPriceCents {
    self = [super init];
    if (self) {
        _placementID = @"";
        _unitID = @"";
        _adFormat = ([adFormat isKindOfClass:[NSString class]] && adFormat.length > 0) ? [adFormat copy] : @"Unknown";
        _bidPriceCents = (isfinite(bidPriceCents) && bidPriceCents > 0.0) ? bidPriceCents : 0.0;
        _adObject = adObject;
    }
    return self;
}

- (void)notifyBidWinWithPrice:(double)winPrice
                  secondPrice:(double)secondPrice
                        extra:(NSDictionary *)extra {
    @synchronized (self) {
        if (self.hasNotified) {
            return;
        }
        self.hasNotified = YES;
        self.hasNotifiedWin = YES;
    }

    double fallbackPrice = (isfinite(winPrice) && winPrice > 0.0) ? winPrice : self.bidPriceCents;
    double safeSecondPrice = (isfinite(secondPrice) && secondPrice > 0.0) ? secondPrice : fallbackPrice;
    NSInteger secondPriceCents = (NSInteger)llround(safeSecondPrice);
    NSString *secondPriceStr = [NSString stringWithFormat:@"%ld", (long)secondPriceCents];
    NSString *winnerAdn = @"MediaGo";
    if ([extra isKindOfClass:[NSDictionary class]]) {
        id rawAdn = extra[ADMTradPlusParamAdnID] ?: extra[@"adn"];
        if ([rawAdn isKindOfClass:[NSString class]] && [(NSString *)rawAdn length] > 0) {
            winnerAdn = (NSString *)rawAdn;
        } else if ([rawAdn isKindOfClass:[NSNumber class]]) {
            winnerAdn = [(NSNumber *)rawAdn stringValue];
        }
    }

    NSDictionary *secondInfo = @{
        @"ecpm": secondPriceStr,
        @"min_to_win": @(secondPriceCents),
        @"adn": winnerAdn
    };
    self.lastWinSecondInfo = secondInfo;

    id target = self.adObject;
    [ADMTradPlusUtils dispatchOnMainThread:^{
        if ([target respondsToSelector:@selector(biddingSuccessWithSecondInfo:completion:)]) {
            [(id <ADMTradPlusBiddingNotifiable>)target biddingSuccessWithSecondInfo:secondInfo completion:nil];
        }
    }];
}

- (void)notifyBidLossWithLossType:(TPBiddingLossType)lossType
                         winPrice:(double)winPrice
                            extra:(NSDictionary *)extra {
    @synchronized (self) {
        if (self.hasNotified) {
            return;
        }
        self.hasNotified = YES;
        self.hasNotifiedLoss = YES;
    }

    double safeWinPrice = (isfinite(winPrice) && winPrice > 0.0) ? winPrice : self.bidPriceCents;
    NSInteger winPriceCents = (NSInteger)llround(safeWinPrice);
    NSString *winPriceStr = [NSString stringWithFormat:@"%ld", (long)winPriceCents];
    NSInteger admReason = [[self class] mapAdMasterLossReasonFromLossType:lossType];
    NSString *winnerAdn = @"other";
    if ([extra isKindOfClass:[NSDictionary class]]) {
        id rawAdn = extra[ADMTradPlusParamAdnID] ?: extra[@"adn"];
        if ([rawAdn isKindOfClass:[NSString class]] && [(NSString *)rawAdn length] > 0) {
            winnerAdn = (NSString *)rawAdn;
        } else if ([rawAdn isKindOfClass:[NSNumber class]]) {
            winnerAdn = [(NSNumber *)rawAdn stringValue];
        }
    }

    NSMutableDictionary *winInfo = [NSMutableDictionary dictionaryWithDictionary:@{
        @"ecpm": winPriceStr,
        @"min_to_win": @(winPriceCents),
        @"reason": @(admReason),
        @"adn": winnerAdn
    }];
    if ([extra isKindOfClass:[NSDictionary class]] && extra[ADMTradPlusParamAdnID] != nil) {
        winInfo[@"adn_id"] = extra[ADMTradPlusParamAdnID];
    } else {
        winInfo[@"adn_id"] = @(10);
    }
    self.lastLossWinInfo = [winInfo copy];

    id target = self.adObject;
    [ADMTradPlusUtils dispatchOnMainThread:^{
        if ([target respondsToSelector:@selector(biddingFailWithWinInfo:completion:)]) {
            [(id <ADMTradPlusBiddingNotifiable>)target biddingFailWithWinInfo:self.lastLossWinInfo completion:nil];
        }
    }];
}

- (void)handleTradPlusWinInfo:(NSDictionary *)info {
    double secondPrice = 0.0;
    double winPrice = self.bidPriceCents;
    if ([info isKindOfClass:[NSDictionary class]]) {
        if (info[@"secondPirce"] != nil && [info[@"secondPirce"] respondsToSelector:@selector(doubleValue)]) {
            // TradPlus C2S reports secondPirce in USD (same unit as C2SBiddingFinish ecpm) -> convert to cents
            secondPrice = [info[@"secondPirce"] doubleValue] * 100.0;
        } else {
            id rawSecond = info[ADMTradPlusParamSecondPrice] ?: info[@"secondPrice"] ?: info[@"ecpm"];
            if ([rawSecond respondsToSelector:@selector(doubleValue)]) {
                secondPrice = [rawSecond doubleValue];
            }
        }
        if (info[@"topPirce"] != nil && [info[@"topPirce"] respondsToSelector:@selector(doubleValue)]) {
            winPrice = [info[@"topPirce"] doubleValue] * 100.0;
        } else {
            id rawWin = info[ADMTradPlusParamWinPrice] ?: info[@"winPrice"] ?: info[@"topPirce_cny"] ?: info[ADMTradPlusParamECPM];
            if ([rawWin respondsToSelector:@selector(doubleValue)]) {
                winPrice = [rawWin doubleValue];
            }
        }
    }
    [self notifyBidWinWithPrice:winPrice secondPrice:secondPrice extra:info];
}

- (void)handleTradPlusLossInfo:(NSDictionary *)info {
    double winPrice = 0.0;
    TPBiddingLossType lossType = TPBiddingLossTypeLowPriceInNormal;
    if ([info isKindOfClass:[NSDictionary class]]) {
        if (info[@"topPirce"] != nil && [info[@"topPirce"] respondsToSelector:@selector(doubleValue)]) {
            // TradPlus C2S reports topPirce in USD -> convert to cents
            winPrice = [info[@"topPirce"] doubleValue] * 100.0;
        } else {
            id rawWin = info[ADMTradPlusParamWinPrice] ?: info[@"winPrice"] ?: info[@"topPirce_cny"] ?: info[ADMTradPlusParamECPM];
            if ([rawWin respondsToSelector:@selector(doubleValue)]) {
                winPrice = [rawWin doubleValue];
            }
        }
        id rawReason = info[ADMTradPlusParamLossReason] ?: info[@"lossReason"] ?: info[@"reason"];
        if (rawReason != nil) {
            lossType = [[self class] parseLossReasonFromValue:rawReason];
        }
    }
    [self notifyBidLossWithLossType:lossType winPrice:winPrice extra:info];
}

+ (NSInteger)mapAdMasterLossReasonFromLossType:(TPBiddingLossType)lossType {
    switch ((NSInteger)lossType) {
        case 103: // TPBiddingLossTypeLowPriceInNormal
            return 103;
        case 102: // TPBiddingLossTypeLowPriceInHB
            return 102;
        case 101: // TPBiddingLossTypeBiddingTimeOut -> 101 per Plan 2.3 Spec
        case 2:
            return 101;
        case 5:   // TPBiddingLossTypeExpire
            return 5;
        default:
            return 102;
    }
}

+ (TPBiddingLossType)parseLossReasonFromValue:(id)rawValue {
    if (!rawValue) {
        return TPBiddingLossTypeLowPriceInNormal;
    }
    if ([rawValue isKindOfClass:[NSNumber class]]) {
        NSInteger code = [(NSNumber *)rawValue integerValue];
        if (code == 101 || code == 2 || code == 100) {
            return TPBiddingLossTypeBiddingTimeOut;
        }
        if (code == 102) {
            return TPBiddingLossTypeLowPriceInHB;
        }
        if (code == 103 || code == 1 || code == 203) {
            return TPBiddingLossTypeLowPriceInNormal;
        }
        if (code == 5) {
            return TPBiddingLossTypeExpire;
        }
        return TPBiddingLossTypeOther;
    }
    if ([rawValue isKindOfClass:[NSString class]]) {
        NSString *lower = [[(NSString *)rawValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
        if ([lower containsString:@"timeout"] || [lower containsString:@"time_out"] || [lower isEqualToString:@"101"] || [lower isEqualToString:@"2"] || [lower isEqualToString:@"100"]) {
            return TPBiddingLossTypeBiddingTimeOut;
        }
        if ([lower isEqualToString:@"102"]) {
            return TPBiddingLossTypeLowPriceInHB;
        }
        if ([lower containsString:@"low"] || [lower containsString:@"price"] || [lower containsString:@"floor"] || [lower isEqualToString:@"103"] || [lower isEqualToString:@"1"] || [lower isEqualToString:@"203"]) {
            return TPBiddingLossTypeLowPriceInNormal;
        }
        if ([lower containsString:@"expire"] || [lower isEqualToString:@"5"]) {
            return TPBiddingLossTypeExpire;
        }
        return TPBiddingLossTypeOther;
    }
    return TPBiddingLossTypeLowPriceInNormal;
}

@end
