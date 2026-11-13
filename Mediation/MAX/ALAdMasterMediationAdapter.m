//
//  ALAdMasterMediationAdapter.m
//  Mediation/MAX
//

#import "ALAdMasterMediationAdapter.h"
#import "ALAdMasterNativeAd.h"
#import <AdMasterSDK/AdMasterSDK.h>
#if __has_include(<AppLovinSDK/AppLovinSDK.h>)
#import <AppLovinSDK/AppLovinSDK.h>
#endif
#import <math.h>

NS_ASSUME_NONNULL_BEGIN

#define ADAPTER_VERSION @"2.1.0.1"

static NSString *const kADMMaxServerKeyAppId = @"app_id";
static NSString *const kADMMaxServerKeyAdUnitId = @"ad_unit_id";
static NSString *const kADMMaxServerKeyPlacementId = @"placement_id";
static NSString *const kADMMaxServerKeyCustomParameters = @"custom_parameters";
static NSString *const kADMMaxServerKeyTest = @"test";
static NSString *const kADMMaxServerKeyMock = @"mock";
static NSString *const kADMMaxServerKeyWidth = @"width";
static NSString *const kADMMaxServerKeyHeight = @"height";
static NSString *const kADMMaxServerKeyBannerWidth = @"banner_width";
static NSString *const kADMMaxServerKeyBannerHeight = @"banner_height";
static NSString *const kADMMaxServerKeyBidFloor = @"bid_floor";
static NSString *const kADMMaxServerKeyBidResponse = @"bid_response";
static NSString *const kADMMaxServerKeyBidResponseCamel = @"bidResponse";
static NSString *const kADMMaxServerKeyAdm = @"adm";
static NSString *const kADMMaxServerKeySecondPrice = @"second_price";
static NSString *const kADMMaxServerKeyWinPrice = @"win_price";
static NSString *const kADMMaxServerKeyEcpm = @"ecpm";
static NSString *const kADMMaxServerKeyLossReason = @"loss_reason";
static NSString *const kADMMaxServerKeyReason = @"reason";
static NSString *const kADMMaxServerKeyAdn = @"adn";
static NSString *const kADMMaxServerKeyAdType = @"ad_t";
static NSString *const kADMMaxServerKeyAdName = @"ad_n";
static NSString *const kADMMaxServerKeyBidType = @"bid_t";

#pragma mark - Bidding notifiable protocol

@protocol ADMMaxBiddingNotifiable <NSObject>
@optional
- (nullable NSString *)getECPMLevel;
- (void)biddingSuccessWithSecondInfo:(NSDictionary *)secondInfo
                          completion:(nullable void (^)(BOOL success, NSString *_Nullable errorInfo))completion;
- (void)biddingFailWithWinInfo:(NSDictionary *)winInfo
                    completion:(nullable void (^)(BOOL success, NSString *_Nullable errorInfo))completion;
@end

@protocol ADMMaxBiddingLoadable <NSObject>
@optional
- (void)load;
- (void)loadAd;
- (void)loadBiddingAdWithADMData:(NSString *)admData;
- (void)loadBiddingAdWithTokenId:(NSString *)tokenId;
@end

#pragma mark - Parameter helpers

static NSDictionary *_Nullable ADMMaxDictionaryFromObject(id value) {
    if ([value isKindOfClass:[NSDictionary class]]) {
        return (NSDictionary *)value;
    }
    if (![value isKindOfClass:[NSString class]]) {
        return nil;
    }
    NSString *string = (NSString *)value;
    if (string.length == 0) {
        return nil;
    }
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) {
        return nil;
    }
    id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if (![obj isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    return (NSDictionary *)obj;
}

static NSString *_Nullable ADMMaxStringFromObject(id value) {
    if ([value isKindOfClass:[NSString class]]) {
        return (NSString *)value;
    }
    if ([value isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)value stringValue];
    }
    return nil;
}

static NSString *_Nullable ADMMaxTrimmedString(NSString *_Nullable raw) {
    if (![raw isKindOfClass:[NSString class]]) {
        return nil;
    }
    NSCharacterSet *ws = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *trimmed = [raw stringByTrimmingCharactersInSet:ws];
    return trimmed.length > 0 ? trimmed : nil;
}

static id _Nullable ADMMaxServerParameter(id <MAAdapterParameters> parameters, NSString *key) {
    return parameters.serverParameters[key];
}

static id _Nullable ADMMaxCustomParameter(id <MAAdapterParameters> parameters, NSString *key) {
    id customValue = parameters.customParameters[key];
    if (customValue != nil) {
        return customValue;
    }
    id rawCustom = ADMMaxServerParameter(parameters, kADMMaxServerKeyCustomParameters);
    NSDictionary *serverCustomParameters = ADMMaxDictionaryFromObject(rawCustom);
    return serverCustomParameters[key];
}

static id _Nullable ADMMaxRuntimeParameter(id <MAAdapterParameters> parameters, NSString *key) {
    id customValue = ADMMaxCustomParameter(parameters, key);
    if (customValue != nil) {
        return customValue;
    }
    if ([parameters respondsToSelector:@selector(localExtraParameters)]) {
        id localValue = parameters.localExtraParameters[key];
        if (localValue != nil) {
            return localValue;
        }
    }
    return ADMMaxServerParameter(parameters, key);
}

static NSString *_Nullable ADMMaxResolvedAppId(id <MAAdapterParameters> parameters) {
    NSString *appId = ADMMaxStringFromObject(ADMMaxRuntimeParameter(parameters, kADMMaxServerKeyAppId));
    return ADMMaxTrimmedString(appId);
}

static NSString *_Nullable ADMMaxResolvedPlacementId(id <MAAdapterParameters> parameters) {
    if ([parameters respondsToSelector:@selector(thirdPartyAdPlacementIdentifier)]) {
        id <MAAdapterResponseParameters> responseParams = (id <MAAdapterResponseParameters>)parameters;
        if ([responseParams.thirdPartyAdPlacementIdentifier al_isValidString]) {
            return ADMMaxTrimmedString(responseParams.thirdPartyAdPlacementIdentifier);
        }
    }
    NSString *adUnitId = ADMMaxStringFromObject(ADMMaxRuntimeParameter(parameters, kADMMaxServerKeyAdUnitId));
    if ([adUnitId al_isValidString]) {
        return ADMMaxTrimmedString(adUnitId);
    }
    NSString *placementId = ADMMaxStringFromObject(ADMMaxRuntimeParameter(parameters, kADMMaxServerKeyPlacementId));
    return ADMMaxTrimmedString(placementId);
}

static BOOL ADMMaxBoolFromServerValue(id value) {
    if ([value isKindOfClass:[NSNumber class]]) {
        return [value boolValue];
    }
    if ([value isKindOfClass:[NSString class]]) {
        NSString *lower = [(NSString *)value lowercaseString];
        return [lower isEqualToString:@"true"] || [lower isEqualToString:@"yes"] || [lower isEqualToString:@"1"];
    }
    return NO;
}

static CGFloat ADMMaxCGFloatFromServerValue(id value) {
    if ([value isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)value doubleValue];
    }
    if ([value isKindOfClass:[NSString class]]) {
        return [(NSString *)value doubleValue];
    }
    return 0;
}

static NSInteger ADMMaxPositiveIntegerFromValue(id value) {
    if ([value isKindOfClass:[NSNumber class]]) {
        double v = [(NSNumber *)value doubleValue];
        if (isfinite(v) && v > 0.0) {
            return (v >= (double)INT_MAX) ? INT_MAX : (NSInteger)llround(v);
        }
        return 0;
    }
    if ([value isKindOfClass:[NSString class]]) {
        NSString *trimmed = ADMMaxTrimmedString((NSString *)value);
        if (trimmed.length > 0) {
            double v = [trimmed doubleValue];
            if (isfinite(v) && v > 0.0) {
                return (v >= (double)INT_MAX) ? INT_MAX : (NSInteger)llround(v);
            }
        }
    }
    return 0;
}

static NSURL *_Nullable ADMMaxURLWithString(NSString *string) {
    if (string.length == 0) {
        return nil;
    }
    NSURL *url = [NSURL URLWithString:string];
    if (!url) {
        NSCharacterSet *allowed = [NSCharacterSet URLQueryAllowedCharacterSet];
        NSString *encodedString = [string stringByAddingPercentEncodingWithAllowedCharacters:allowed];
        url = [NSURL URLWithString:encodedString];
    }
    return url;
}

static void ADMMaxUpdateAdMasterRuntimeFromParameters(id <MAAdapterParameters> parameters) {
    BOOL test = ADMMaxBoolFromServerValue(ADMMaxRuntimeParameter(parameters, kADMMaxServerKeyTest));
    BOOL mock = ADMMaxBoolFromServerValue(ADMMaxRuntimeParameter(parameters, kADMMaxServerKeyMock));
    [ADMSetting sharedInstance].isTest = test;
    [ADMSetting sharedInstance].isMock = mock;

    BOOL limitPersonalAds = NO;
    NSNumber *hasConsent = [parameters hasUserConsent];
    if (hasConsent != nil && !hasConsent.boolValue) {
        limitPersonalAds = YES;
    }
    NSNumber *doNotSell = [parameters isDoNotSell];
    if (doNotSell != nil && doNotSell.boolValue) {
        limitPersonalAds = YES;
    }
    if (hasConsent != nil || doNotSell != nil) {
        [[ADMSetting sharedInstance] setLimitPersonalAds:limitPersonalAds];
    }
}

static NSString *_Nullable ADMMaxResolvedBidResponse(id <MAAdapterParameters> _Nullable parameters) {
    if (!parameters) {
        return nil;
    }
    if ([parameters respondsToSelector:@selector(bidResponse)]) {
        NSString *direct = ADMMaxTrimmedString(((id <MAAdapterResponseParameters>)parameters).bidResponse);
        if (direct.length > 0) {
            return direct;
        }
    }
    NSArray<NSString *> *keys = @[
        kADMMaxServerKeyBidResponse,
        kADMMaxServerKeyBidResponseCamel,
        kADMMaxServerKeyAdm
    ];
    for (NSString *key in keys) {
        id raw = ADMMaxRuntimeParameter(parameters, key);
        if ([raw isKindOfClass:[NSDictionary class]] && [NSJSONSerialization isValidJSONObject:raw]) {
            NSData *data = [NSJSONSerialization dataWithJSONObject:raw options:0 error:nil];
            if (data.length > 0) {
                NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSString *trimmedJson = ADMMaxTrimmedString(json);
                if (trimmedJson.length > 0) {
                    return trimmedJson;
                }
            }
        }
        NSString *candidate = ADMMaxTrimmedString(ADMMaxStringFromObject(raw));
        if (candidate.length > 0) {
            return candidate;
        }
    }
    return nil;
}

static BOOL ADMMaxIsBiddingParameters(id <MAAdapterParameters> _Nullable parameters) {
    return ADMMaxResolvedBidResponse(parameters).length > 0;
}

static BOOL ADMMaxIsADMJsonPayload(NSString *bidResponse) {
    NSString *trimmed = ADMMaxTrimmedString(bidResponse);
    if (!trimmed) {
        return NO;
    }
    return [trimmed hasPrefix:@"{"];
}

// Maps a unified ADMPublicErrorDomain NSError to a MAX MAAdapterError.
static MAAdapterError *ADMMaxAdapterErrorFromNSError(NSError *error) {
    if (![error.domain isEqualToString:ADMPublicErrorDomain]) {
        return [MAAdapterError errorWithAdapterError:MAAdapterError.unspecified
                            mediatedNetworkErrorCode:(int)error.code
                         mediatedNetworkErrorMessage:error.localizedDescription ?: @""];
    }
    MAAdapterError *inner;
    switch ((ADMErrorCode)error.code) {
        case ADMErrorCodeNoFill:         inner = MAAdapterError.noFill; break;
        case ADMErrorCodeInvalidConfig:  inner = MAAdapterError.badRequest; break;
        case ADMErrorCodeInvalidContent: inner = MAAdapterError.invalidConfiguration; break;
        case ADMErrorCodeShowFailed:
        case ADMErrorCodePlaybackFailed: inner = MAAdapterError.adDisplayFailedError; break;
        default:                         inner = MAAdapterError.unspecified; break;
    }
    NSString *serverCode = error.userInfo[ADMServerErrorCodeKey];
    NSInteger code = serverCode.length > 0 ? serverCode.integerValue : error.code;
    return [MAAdapterError errorWithAdapterError:inner
                        mediatedNetworkErrorCode:(int)code
                     mediatedNetworkErrorMessage:error.localizedDescription ?: @""];
}

static NSString *ADMMaxAdViewFormatLabel(MAAdFormat *adFormat) {
    if (adFormat == MAAdFormat.leader) {
        return @"leader";
    }
    if (adFormat == MAAdFormat.mrec) {
        return @"mrec";
    }
    if (adFormat == MAAdFormat.banner) {
        return @"banner";
    }
    return @"ad view";
}

static CGSize ADMMaxAppOpenAdSize(void) {
    CGSize size = [UIScreen mainScreen].bounds.size;
    return CGSizeMake(MAX(size.width, 200.0), MAX(size.height, 200.0));
}

static CGSize ADMMaxDefaultAdViewSize(MAAdFormat *adFormat) {
    if (adFormat == MAAdFormat.leader) {
        return CGSizeMake(728, 90);
    }
    if (adFormat == MAAdFormat.mrec) {
        return CGSizeMake(300, 250);
    }
    return CGSizeMake(320, 50);
}

static CGSize ADMMaxResolvedAdViewSize(id <MAAdapterParameters> parameters, MAAdFormat *adFormat) {
    CGSize size = ADMMaxDefaultAdViewSize(adFormat);
    CGFloat width = ADMMaxCGFloatFromServerValue(ADMMaxRuntimeParameter(parameters, kADMMaxServerKeyBannerWidth));
    CGFloat height = ADMMaxCGFloatFromServerValue(ADMMaxRuntimeParameter(parameters, kADMMaxServerKeyBannerHeight));
    if (width <= 0) {
        width = ADMMaxCGFloatFromServerValue(ADMMaxRuntimeParameter(parameters, kADMMaxServerKeyWidth));
    }
    if (height <= 0) {
        height = ADMMaxCGFloatFromServerValue(ADMMaxRuntimeParameter(parameters, kADMMaxServerKeyHeight));
    }
    if (width > 0 && height > 0) {
        size = CGSizeMake(width, height);
    }
    return size;
}

static UIWindow *_Nullable ADMMaxKeyWindow(void) {
    UIWindow *keyWindow = nil;
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState != UISceneActivationStateForegroundActive) {
                continue;
            }
            if (![scene isKindOfClass:[UIWindowScene class]]) {
                continue;
            }
            for (UIWindow *window in ((UIWindowScene *)scene).windows) {
                if (window.isKeyWindow) {
                    keyWindow = window;
                    break;
                }
            }
            if (keyWindow) {
                break;
            }
        }
    }
    return keyWindow ?: [UIApplication sharedApplication].keyWindow;
}

static void ADMMaxRunOnMain(void (^block)(void)) {
    if (!block) {
        return;
    }
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

#pragma mark - Bidding reporter

@interface ALAdMasterBiddingReporter : NSObject
@property (nonatomic, strong, nullable) id <MAAdapterResponseParameters> parameters;
@property (nonatomic, assign, readonly) BOOL isBidding;
@property (nonatomic, assign, readwrite) BOOL invalidated;
@property (nonatomic, assign, readwrite) BOOL hasReportedWin;
@property (nonatomic, assign, readwrite) BOOL hasReportedLoss;
@property (nonatomic, copy, readwrite, nullable) NSDictionary *lastWinSecondInfo;
@property (nonatomic, copy, readwrite, nullable) NSDictionary *lastLossWinInfo;

- (instancetype)initWithParameters:(nullable id <MAAdapterResponseParameters>)parameters;
- (void)invalidate;
- (void)reportBidWinForAd:(nullable id)adObject;
- (void)reportBidLossForAd:(nullable id)adObject error:(nullable NSError *)error;
- (void)reportBidLossForAd:(nullable id)adObject reasonCode:(NSInteger)reasonCode;
+ (NSInteger)lossReasonFromError:(nullable NSError *)error
                      parameters:(nullable id <MAAdapterParameters>)parameters;
@end

@implementation ALAdMasterBiddingReporter

- (instancetype)initWithParameters:(nullable id <MAAdapterResponseParameters>)parameters {
    self = [super init];
    if (self) {
        _parameters = parameters;
        _isBidding = ADMMaxIsBiddingParameters(parameters);
    }
    return self;
}

- (void)invalidate {
    @synchronized (self) {
        self.invalidated = YES;
    }
}

+ (NSInteger)normalizedExplicitLossReasonCode:(NSInteger)code {
    if (code <= 0) {
        return 0;
    }
    if (code == 101) {
        return 2;
    }
    return code;
}

+ (NSInteger)lossReasonFromExplicitParameter:(id)rawReason {
    if ([rawReason isKindOfClass:[NSNumber class]]) {
        return [self normalizedExplicitLossReasonCode:[(NSNumber *)rawReason integerValue]];
    }
    if ([rawReason isKindOfClass:[NSString class]]) {
        NSString *lower = [ADMMaxTrimmedString((NSString *)rawReason) lowercaseString];
        if (lower.length == 0) {
            return 0;
        }
        if ([lower containsString:@"timeout"]) {
            return 2;
        }
        if ([lower containsString:@"expire"]) {
            return 5;
        }
        if ([lower containsString:@"floor"]) {
            return 103;
        }
        return [self normalizedExplicitLossReasonCode:[lower integerValue]];
    }
    return 0;
}

+ (NSInteger)lossReasonFromError:(nullable NSError *)error
                      parameters:(nullable id <MAAdapterParameters>)parameters {
    if (parameters) {
        id rawReason = ADMMaxRuntimeParameter(parameters, kADMMaxServerKeyLossReason)
            ?: ADMMaxRuntimeParameter(parameters, kADMMaxServerKeyReason);
        NSInteger explicitCode = [self lossReasonFromExplicitParameter:rawReason];
        if (explicitCode > 0) {
            return explicitCode;
        }
    }
    if (!error) {
        return 102;
    }
    if ([error.domain isEqualToString:NSURLErrorDomain]) {
        return 2;
    }
    if ([error.domain isEqualToString:ADMPublicErrorDomain]) {
        switch ((ADMErrorCode)error.code) {
            case ADMErrorCodeNoFill:         return 102;
            case ADMErrorCodeNetworkError:   return 2;
            case ADMErrorCodeInvalidConfig:  return 103;
            case ADMErrorCodeDownloadFailed:
            case ADMErrorCodeCacheFailed:    return 2;
            case ADMErrorCodeInvalidContent: return 900;
            default:                         return 102;
        }
    }
    if (error.code == -5213) {
        return 5;
    }
    if (error.code == -5206) {
        return 2;
    }
    return 102;
}

- (NSInteger)resolvedPriceCentsForAd:(nullable id)adObject primaryKey:(NSString *)primaryKey {
    if (self.parameters) {
        NSInteger primary = ADMMaxPositiveIntegerFromValue(ADMMaxRuntimeParameter(self.parameters, primaryKey));
        if (primary > 0) {
            return primary;
        }
        NSInteger ecpmParam = ADMMaxPositiveIntegerFromValue(
            ADMMaxRuntimeParameter(self.parameters, kADMMaxServerKeyEcpm));
        if (ecpmParam > 0) {
            return ecpmParam;
        }
    }
    if ([adObject respondsToSelector:@selector(getECPMLevel)]) {
        NSString *adEcpm = [(id <ADMMaxBiddingNotifiable>)adObject getECPMLevel];
        NSInteger parsed = ADMMaxPositiveIntegerFromValue(adEcpm);
        if (parsed > 0) {
            return parsed;
        }
    }
    if (self.parameters) {
        NSInteger floor = ADMMaxPositiveIntegerFromValue(
            ADMMaxRuntimeParameter(self.parameters, kADMMaxServerKeyBidFloor));
        if (floor > 0) {
            return floor;
        }
    }
    return 1;
}

- (NSDictionary *)baseBiddingInfoWithPriceCents:(NSInteger)priceCents {
    NSInteger safePrice = priceCents > 0 ? priceCents : 1;
    NSInteger adn = 10;
    NSInteger adType = 7;
    NSInteger bidType = 2;
    NSString *adName = @"max";
    if (self.parameters) {
        NSInteger paramAdn = ADMMaxPositiveIntegerFromValue(
            ADMMaxRuntimeParameter(self.parameters, kADMMaxServerKeyAdn));
        if (paramAdn > 0) {
            adn = paramAdn;
        }
        NSInteger paramAdType = ADMMaxPositiveIntegerFromValue(
            ADMMaxRuntimeParameter(self.parameters, kADMMaxServerKeyAdType));
        if (paramAdType > 0) {
            adType = paramAdType;
        }
        NSInteger paramBidType = ADMMaxPositiveIntegerFromValue(
            ADMMaxRuntimeParameter(self.parameters, kADMMaxServerKeyBidType));
        if (paramBidType > 0) {
            bidType = paramBidType;
        }
        NSString *paramAdName = ADMMaxTrimmedString(
            ADMMaxStringFromObject(ADMMaxRuntimeParameter(self.parameters, kADMMaxServerKeyAdName)));
        if (paramAdName.length > 0) {
            adName = paramAdName;
        }
    }
    NSString *timestamp = [NSString stringWithFormat:@"%ld", (long)[[NSDate date] timeIntervalSince1970]];
    return @{
        @"ecpm": [NSString stringWithFormat:@"%ld", (long)safePrice],
        @"min_to_win": @(safePrice),
        @"adn": @(adn),
        @"ad_t": @(adType),
        @"ad_n": adName,
        @"ad_time": timestamp,
        @"bid_t": @(bidType)
    };
}

- (void)reportBidWinForAd:(nullable id)adObject {
    if (!self.isBidding || !adObject) {
        return;
    }
    if (![adObject respondsToSelector:@selector(biddingSuccessWithSecondInfo:completion:)]) {
        return;
    }
    @synchronized (self) {
        if (self.invalidated || self.hasReportedWin || self.hasReportedLoss) {
            return;
        }
        self.hasReportedWin = YES;
    }
    NSInteger priceCents = [self resolvedPriceCentsForAd:adObject primaryKey:kADMMaxServerKeySecondPrice];
    NSDictionary *secondInfo = [self baseBiddingInfoWithPriceCents:priceCents];
    self.lastWinSecondInfo = secondInfo;
    [(id <ADMMaxBiddingNotifiable>)adObject biddingSuccessWithSecondInfo:secondInfo completion:nil];
}

- (void)reportBidLossForAd:(nullable id)adObject error:(nullable NSError *)error {
    NSInteger reasonCode = [[self class] lossReasonFromError:error parameters:self.parameters];
    [self reportBidLossForAd:adObject reasonCode:reasonCode];
}

- (void)reportBidLossForAd:(nullable id)adObject reasonCode:(NSInteger)reasonCode {
    if (!self.isBidding || !adObject) {
        return;
    }
    if (![adObject respondsToSelector:@selector(biddingFailWithWinInfo:completion:)]) {
        return;
    }
    @synchronized (self) {
        if (self.invalidated || self.hasReportedLoss || self.hasReportedWin) {
            return;
        }
        self.hasReportedLoss = YES;
    }
    NSInteger priceCents = [self resolvedPriceCentsForAd:adObject primaryKey:kADMMaxServerKeyWinPrice];
    NSMutableDictionary *winInfo = [[self baseBiddingInfoWithPriceCents:priceCents] mutableCopy];
    winInfo[@"reason"] = @(reasonCode > 0 ? reasonCode : 102);
    winInfo[@"is_s"] = @(0);
    winInfo[@"is_c"] = @(0);
    NSDictionary *finalInfo = [winInfo copy];
    self.lastLossWinInfo = finalInfo;
    [(id <ADMMaxBiddingNotifiable>)adObject biddingFailWithWinInfo:finalInfo completion:nil];
}

@end

#pragma mark - Forward declarations

@interface ALAdMasterMediationAdapter ()
@property (nonatomic, strong, nullable) ADMSplashAd *appOpenAd;
@property (nonatomic, strong, nullable) ADMBannerView *bannerView;
@property (nonatomic, strong, nullable) ADMInterstitialAd *interstitialAd;
@property (nonatomic, strong, nullable) ADMRewardedAd *rewardedAd;
@property (nonatomic, strong, nullable) ADMNativeAdLoader *nativeLoader;

@property (nonatomic, strong, nullable) NSObject *appOpenBridge;
@property (nonatomic, strong, nullable) NSObject *bannerBridge;
@property (nonatomic, strong, nullable) NSObject *interstitialBridge;
@property (nonatomic, strong, nullable) NSObject *rewardedBridge;
@property (nonatomic, strong, nullable) NSObject *nativeLoadSession;

@property (nonatomic, weak, nullable) UIViewController *nativePresentingViewController;
@property (atomic, assign) BOOL isDestroyed;

- (ADMInterstitialAd *)createInterstitialAd;
- (ADMRewardedAd *)createRewardedAd;
- (ADMSplashAd *)createAppOpenAd;
- (ADMBannerView *)createBannerViewWithSize:(CGSize)size adUnitTag:(NSString *)adUnitTag;
- (ADMNativeAdLoader *)createNativeAdLoader;
@end

static ALAtomicBoolean *ALAdMasterInitLock;
static MAAdapterInitializationStatus ALAdMasterInitStatus = NSIntegerMin;
static NSString *_Nullable ALAdMasterInitErrorMessage = nil;
static NSString *_Nullable ALAdMasterConfiguredAppId = nil;
static NSUInteger ALAdMasterConfigGeneration = 0;

#pragma mark - App open bridge

@interface ALAdMasterAppOpenBridge : NSObject <ADMSplashDelegate, ADMFullScreenContentDelegate>
@property (atomic, weak, nullable) ALAdMasterMediationAdapter *parent;
@property (atomic, weak, nullable) ADMSplashAd *targetAd;
@property (atomic, strong, nullable) id <MAAppOpenAdapterDelegate> delegate;
@property (atomic, strong, nullable) ALAdMasterBiddingReporter *biddingReporter;
@property (nonatomic, assign) BOOL didNotifyLoad;
@property (nonatomic, assign) BOOL didReportDisplay;
@property (atomic, assign) BOOL invalidated;
- (void)invalidate;
@end

@implementation ALAdMasterAppOpenBridge

- (instancetype)initWithParent:(ALAdMasterMediationAdapter *)parent
                      delegate:(id <MAAppOpenAdapterDelegate>)delegate
               biddingReporter:(nullable ALAdMasterBiddingReporter *)biddingReporter {
    self = [super init];
    if (self) {
        _parent = parent;
        _delegate = delegate;
        _biddingReporter = biddingReporter;
    }
    return self;
}

- (void)invalidate {
    self.invalidated = YES;
    [self.biddingReporter invalidate];
    self.delegate = nil;
    self.parent = nil;
}

- (void)splashAd:(ADMSplashAd *)splashAd didFailToReceiveAdWithError:(NSError *)error {
    __weak typeof(self) weakSelf = self;
    MAAdapterError *adapterError = ADMMaxAdapterErrorFromNSError(error);
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.invalidated) {
            return;
        }
        [self.biddingReporter reportBidLossForAd:(splashAd ?: self.targetAd) error:error];
        [self.parent log:@"AdMaster app open load failed: %@", error.localizedDescription];
        [self.delegate didFailToLoadAppOpenAdWithError:adapterError];
    });
}

- (void)splashAdDidReceiveAd:(ADMSplashAd *)splash {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.invalidated || self.didNotifyLoad) {
            return;
        }
        ADMSplashAd *ad = splash ?: self.targetAd;
        if (![ad isReady]) {
            return;
        }
        self.didNotifyLoad = YES;
        [self.biddingReporter reportBidWinForAd:ad];
        [self.parent log:@"AdMaster app open loaded."];
        [self.delegate didLoadAppOpenAd];
    });
}

- (void)adWillPresentFullScreenContent:(ADMSplashAd *)splash {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.invalidated || self.didReportDisplay) {
            return;
        }
        self.didReportDisplay = YES;
        [self.biddingReporter reportBidWinForAd:(splash ?: self.targetAd)];
        [self.delegate didDisplayAppOpenAd];
    });
}

- (void)ad:(ADMSplashAd *)splash didFailToPresentFullScreenContentWithError:(NSError *)error {
    __weak typeof(self) weakSelf = self;
    MAAdapterError *adapterError = ADMMaxAdapterErrorFromNSError(error);
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.invalidated) {
            return;
        }
        [self.biddingReporter reportBidLossForAd:(splash ?: self.targetAd) error:error];
        [self.parent log:@"AdMaster app open display failed: %@", error.localizedDescription];
        [self.delegate didFailToDisplayAppOpenAdWithError:adapterError];
    });
}

- (void)adDidRecordClick:(ADMSplashAd *)splash {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.invalidated) {
            return;
        }
        [self.delegate didClickAppOpenAd];
    });
}

- (void)adWillDismissFullScreenContent:(ADMSplashAd *)splash {
}

- (void)adDidDismissFullScreenContent:(ADMSplashAd *)splash {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.invalidated) {
            return;
        }
        [self.delegate didHideAppOpenAd];
    });
}

@end

#pragma mark - Banner bridge

@interface ALAdMasterBannerBridge : NSObject <ADMBannerDelegate>
@property (atomic, weak, nullable) ALAdMasterMediationAdapter *parent;
@property (atomic, weak, nullable) ADMBannerView *targetAd;
@property (atomic, strong, nullable) id <MAAdViewAdapterDelegate> delegate;
@property (nonatomic, copy) NSString *formatLabel;
@property (atomic, strong, nullable) ALAdMasterBiddingReporter *biddingReporter;
@property (atomic, assign) BOOL invalidated;
- (void)invalidate;
@end

@implementation ALAdMasterBannerBridge

- (instancetype)initWithParent:(ALAdMasterMediationAdapter *)parent
                      delegate:(id <MAAdViewAdapterDelegate>)delegate
                   formatLabel:(NSString *)formatLabel
               biddingReporter:(nullable ALAdMasterBiddingReporter *)biddingReporter {
    self = [super init];
    if (self) {
        _parent = parent;
        _delegate = delegate;
        _formatLabel = [formatLabel copy] ?: @"ad view";
        _biddingReporter = biddingReporter;
    }
    return self;
}

- (void)invalidate {
    self.invalidated = YES;
    [self.biddingReporter invalidate];
    self.delegate = nil;
    self.parent = nil;
}

- (void)bannerViewDidReceiveAd:(ADMBannerView *)bannerView {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.invalidated) {
            return;
        }
        ADMBannerView *ad = bannerView ?: self.targetAd;
        [self.biddingReporter reportBidWinForAd:ad];
        [self.parent log:@"AdMaster %@ loaded.", self.formatLabel];
        [self.delegate didLoadAdForAdView:ad];
    });
}

- (void)bannerView:(ADMBannerView *)bannerView didFailToReceiveAdWithError:(NSError *)error {
    __weak typeof(self) weakSelf = self;
    NSString *message = error.localizedDescription ?: @"Unknown ad view load error";
    MAAdapterError *adapterError = ADMMaxAdapterErrorFromNSError(error);
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.invalidated) {
            return;
        }
        [self.biddingReporter reportBidLossForAd:(bannerView ?: self.targetAd) error:error];
        [self.parent log:@"AdMaster %@ load failed: %@", self.formatLabel, message];
        [self.delegate didFailToLoadAdViewAdWithError:adapterError];
    });
}

- (void)bannerView:(ADMBannerView *)bannerView didFailToDisplayAdWithError:(NSError *)error {
    __weak typeof(self) weakSelf = self;
    NSString *message = error.localizedDescription ?: @"Unknown ad view display error";
    MAAdapterError *adapterError = ADMMaxAdapterErrorFromNSError(error);
    if (!adapterError) {
        adapterError = [MAAdapterError errorWithAdapterError:MAAdapterError.adDisplayFailedError
                                    mediatedNetworkErrorCode:error ? (int)error.code : -1
                                 mediatedNetworkErrorMessage:message];
    }
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.invalidated) {
            return;
        }
        [self.biddingReporter reportBidLossForAd:(bannerView ?: self.targetAd) error:error];
        [self.parent log:@"AdMaster %@ display failed: %@", self.formatLabel, message];
        [self.delegate didFailToDisplayAdViewAdWithError:adapterError];
    });
}

- (void)bannerViewDidRecordImpression:(ADMBannerView *)bannerView {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.invalidated) {
            return;
        }
        [self.biddingReporter reportBidWinForAd:(bannerView ?: self.targetAd)];
        [self.delegate didDisplayAdViewAd];
    });
}

- (void)bannerViewDidRecordClick:(ADMBannerView *)bannerView {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.invalidated) {
            return;
        }
        [self.delegate didClickAdViewAd];
    });
}

- (void)bannerViewDidDismiss:(ADMBannerView *)bannerView {
}

@end

#pragma mark - Interstitial bridge

@interface ALAdMasterInterstitialBridge : NSObject <ADMInterstitialDelegate, ADMFullScreenContentDelegate>
@property (atomic, weak, nullable) ALAdMasterMediationAdapter *parent;
@property (atomic, weak, nullable) ADMInterstitialAd *targetAd;
@property (atomic, strong, nullable) id <MAInterstitialAdapterDelegate> delegate;
@property (atomic, strong, nullable) ALAdMasterBiddingReporter *biddingReporter;
@property (nonatomic, assign) BOOL didNotifyLoad;
@property (nonatomic, assign) BOOL didReportDisplay;
@property (atomic, assign) BOOL invalidated;
- (void)invalidate;
@end

@implementation ALAdMasterInterstitialBridge

- (instancetype)initWithParent:(ALAdMasterMediationAdapter *)parent
                      delegate:(id <MAInterstitialAdapterDelegate>)delegate
               biddingReporter:(nullable ALAdMasterBiddingReporter *)biddingReporter {
    self = [super init];
    if (self) {
        _parent = parent;
        _delegate = delegate;
        _biddingReporter = biddingReporter;
    }
    return self;
}

- (void)invalidate {
    self.invalidated = YES;
    [self.biddingReporter invalidate];
    self.delegate = nil;
    self.parent = nil;
}

- (void)interstitialAdDidReceiveAd:(ADMInterstitialAd *)interstitial {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.invalidated || self.didNotifyLoad) {
            return;
        }
        self.didNotifyLoad = YES;
        [self.biddingReporter reportBidWinForAd:(interstitial ?: self.targetAd)];
        [self.parent log:@"AdMaster interstitial loaded."];
        [self.delegate didLoadInterstitialAd];
    });
}

- (void)interstitialAd:(ADMInterstitialAd *)interstitial didFailToReceiveAdWithError:(NSError *)error {
    __weak typeof(self) weakSelf = self;
    MAAdapterError *adapterError = ADMMaxAdapterErrorFromNSError(error);
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.invalidated) {
            return;
        }
        [self.biddingReporter reportBidLossForAd:(interstitial ?: self.targetAd) error:error];
        [self.parent log:@"AdMaster interstitial load failed: %@", error.localizedDescription];
        [self.delegate didFailToLoadInterstitialAdWithError:adapterError];
    });
}

- (void)adWillPresentFullScreenContent:(ADMInterstitialAd *)interstitial {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.invalidated || self.didReportDisplay) {
            return;
        }
        self.didReportDisplay = YES;
        [self.biddingReporter reportBidWinForAd:(interstitial ?: self.targetAd)];
        [self.delegate didDisplayInterstitialAd];
    });
}

- (void)ad:(ADMInterstitialAd *)interstitial didFailToPresentFullScreenContentWithError:(NSError *)error {
    __weak typeof(self) weakSelf = self;
    MAAdapterError *adapterError = ADMMaxAdapterErrorFromNSError(error);
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.invalidated) {
            return;
        }
        [self.biddingReporter reportBidLossForAd:(interstitial ?: self.targetAd) error:error];
        [self.delegate didFailToDisplayInterstitialAdWithError:adapterError];
    });
}

- (void)adWillDismissFullScreenContent:(ADMInterstitialAd *)interstitial {
}

- (void)adDidDismissFullScreenContent:(ADMInterstitialAd *)interstitial {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.invalidated) {
            return;
        }
        [self.delegate didHideInterstitialAd];
    });
}

- (void)adDidRecordClick:(ADMInterstitialAd *)interstitial {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.invalidated) {
            return;
        }
        [self.delegate didClickInterstitialAd];
    });
}

- (void)adDidRecordImpression:(ADMInterstitialAd *)interstitial {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.invalidated || self.didReportDisplay) {
            return;
        }
        self.didReportDisplay = YES;
        [self.biddingReporter reportBidWinForAd:(interstitial ?: self.targetAd)];
        [self.parent log:@"AdMaster interstitial impressed (display)."];
        [self.delegate didDisplayInterstitialAd];
    });
}

@end

#pragma mark - Rewarded bridge

@interface ALAdMasterRewardedBridge : NSObject <ADMRewardedDelegate, ADMFullScreenContentDelegate>
@property (atomic, weak, nullable) ALAdMasterMediationAdapter *parent;
@property (atomic, weak, nullable) ADMRewardedAd *targetAd;
@property (atomic, strong, nullable) id <MARewardedAdapterDelegate> delegate;
@property (atomic, strong, nullable) ALAdMasterBiddingReporter *biddingReporter;
@property (nonatomic, assign) BOOL didNotifyLoad;
@property (nonatomic, assign) BOOL hasGrantedReward;
@property (nonatomic, assign) BOOL hasCalledDisplay;
@property (atomic, assign) BOOL invalidated;
- (void)invalidate;
@end

@implementation ALAdMasterRewardedBridge

- (instancetype)initWithParent:(ALAdMasterMediationAdapter *)parent
                      delegate:(id <MARewardedAdapterDelegate>)delegate
               biddingReporter:(nullable ALAdMasterBiddingReporter *)biddingReporter {
    self = [super init];
    if (self) {
        _parent = parent;
        _delegate = delegate;
        _biddingReporter = biddingReporter;
    }
    return self;
}

- (void)invalidate {
    self.invalidated = YES;
    [self.biddingReporter invalidate];
    self.delegate = nil;
    self.parent = nil;
}

- (void)rewardedAdDidReceiveAd:(ADMRewardedAd *)video {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.invalidated || self.didNotifyLoad) {
            return;
        }
        self.didNotifyLoad = YES;
        [self.biddingReporter reportBidWinForAd:(video ?: self.targetAd)];
        [self.parent log:@"AdMaster rewarded loaded."];
        [self.delegate didLoadRewardedAd];
    });
}

- (void)rewardedAd:(ADMRewardedAd *)video didFailToReceiveAdWithError:(NSError *)error {
    __weak typeof(self) weakSelf = self;
    MAAdapterError *adapterError = ADMMaxAdapterErrorFromNSError(error);
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.invalidated) {
            return;
        }
        [self.biddingReporter reportBidLossForAd:(video ?: self.targetAd) error:error];
        [self.parent log:@"AdMaster rewarded load failed: %@", error.localizedDescription];
        [self.delegate didFailToLoadRewardedAdWithError:adapterError];
    });
}

- (void)rewardedAd:(ADMRewardedAd *)video userDidEarnReward:(ADMReward *)reward {
    [self grantRewardIfNeeded];
}

- (void)ad:(ADMRewardedAd *)video didFailToPresentFullScreenContentWithError:(NSError *)error {
    __weak typeof(self) weakSelf = self;
    MAAdapterError *adapterError = ADMMaxAdapterErrorFromNSError(error);
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.invalidated) {
            return;
        }
        [self.biddingReporter reportBidLossForAd:(video ?: self.targetAd) error:error];
        [self.delegate didFailToDisplayRewardedAdWithError:adapterError];
    });
}

- (void)adWillPresentFullScreenContent:(ADMRewardedAd *)video {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.invalidated) {
            return;
        }
        [self.biddingReporter reportBidWinForAd:(video ?: self.targetAd)];
        if (!self.hasCalledDisplay) {
            self.hasCalledDisplay = YES;
            [self.delegate didDisplayRewardedAd];
        }
    });
}

- (void)adDidRecordImpression:(ADMRewardedAd *)video {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.invalidated) {
            return;
        }
        [self.biddingReporter reportBidWinForAd:(video ?: self.targetAd)];
    });
}

- (void)adDidRecordClick:(ADMRewardedAd *)video {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.invalidated) {
            return;
        }
        [self.delegate didClickRewardedAd];
    });
}

- (void)adDidDismissFullScreenContent:(ADMRewardedAd *)video {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.invalidated) {
            return;
        }
        if ([self.parent shouldAlwaysRewardUser]) {
            [self grantRewardIfNeeded];
        }
        [self.delegate didHideRewardedAd];
    });
}

- (void)grantRewardIfNeeded {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.invalidated || self.hasGrantedReward) {
            return;
        }
        self.hasGrantedReward = YES;
        MAReward *reward = self.parent.reward ?: [MAReward rewardWithAmount:MAReward.defaultAmount label:@""];
        [self.delegate didRewardUserWithReward:reward];
    });
}

@end

#pragma mark - Native load session

@interface ALAdMasterNativeLoadSession : NSObject <ADMNativeAdLoaderDelegate,
                                                   ADMNativeInteractionDelegate,
                                                   ADMNativeVideoViewDelegate>
@property (atomic, weak, nullable) ALAdMasterMediationAdapter *parent;
@property (atomic, weak, nullable) ADMNativeAdLoader *targetLoader;
@property (atomic, strong, nullable) id <MANativeAdAdapterDelegate> delegate;
@property (atomic, strong, nullable) ALAdMasterBiddingReporter *biddingReporter;
@property (atomic, weak, nullable) UIViewController *presentingViewController;
@property (atomic, assign) BOOL invalidated;
- (void)invalidate;
@end

@implementation ALAdMasterNativeLoadSession

- (instancetype)initWithParent:(ALAdMasterMediationAdapter *)parent
                      delegate:(id <MANativeAdAdapterDelegate>)delegate
               biddingReporter:(nullable ALAdMasterBiddingReporter *)biddingReporter {
    self = [super init];
    if (self) {
        _parent = parent;
        _delegate = delegate;
        _biddingReporter = biddingReporter;
    }
    return self;
}

- (void)invalidate {
    self.invalidated = YES;
    [self.biddingReporter invalidate];
    self.delegate = nil;
    self.parent = nil;
}

- (void)loadImageFromURLString:(NSString *)urlString
                nativeAdObject:(ADMNativeAdObject *)nativeAdObject
                    completion:(void (^)(UIImage *_Nullable image))completion {
    if (self.invalidated || urlString.length == 0 || !nativeAdObject) {
        if (completion) {
            completion(nil);
        }
        return;
    }
    __weak typeof(self) weakSelf = self;
    [nativeAdObject loadImageWithURLString:urlString completion:^(UIImage *_Nullable image) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || strongSelf.invalidated) {
            return;
        }
        if (completion) {
            completion(image);
        }
    }];
}

- (void)nativeAdLoader:(ADMNativeAdLoader *)loader didReceiveNativeAds:(NSArray<ADMNativeAdObject *> *)nativeAds {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.invalidated) {
            return;
        }
        [self.parent log:@"AdMaster native objects success. count=%lu", (unsigned long)nativeAds.count];
        if (!nativeAds.count || ![nativeAds.firstObject isKindOfClass:[ADMNativeAdObject class]]) {
            [self.biddingReporter reportBidLossForAd:(loader ?: self.targetLoader) reasonCode:102];
            MAAdapterError *err = [MAAdapterError errorWithAdapterError:MAAdapterError.noFill
                                               mediatedNetworkErrorCode:-1
                                            mediatedNetworkErrorMessage:@"No native ad object"];
            [self.parent log:@"AdMaster native load failed: no valid ADMNativeAdObject"];
            [self.delegate didFailToLoadNativeAdWithError:err];
            return;
        }
        ADMNativeAdObject *obj = nativeAds.firstObject;
        if ([obj isExpired]) {
            [self.biddingReporter reportBidLossForAd:obj reasonCode:5];
            MAAdapterError *err = [MAAdapterError errorWithAdapterError:MAAdapterError.adExpiredError
                                               mediatedNetworkErrorCode:-1
                                            mediatedNetworkErrorMessage:@"Native ad expired"];
            [self.delegate didFailToLoadNativeAdWithError:err];
            return;
        }
        [self adm_finishNativeLoadWithObject:obj];
    });
}

- (nullable MANativeAdImage *)adm_nativeImageWithImage:(nullable UIImage *)image
                                             urlString:(nullable NSString *)urlString {
    if (image) {
        return [[MANativeAdImage alloc] initWithImage:image];
    }
    if (urlString.length > 0) {
        NSURL *url = ADMMaxURLWithString(urlString);
        if (url) {
            return [[MANativeAdImage alloc] initWithURL:url];
        }
    }
    return nil;
}

- (nullable UIView *)adm_mediaViewForObject:(ADMNativeAdObject *)obj
                                  mainImage:(nullable UIImage *)mainImage
                               videoViewOut:(ADMNativeVideoView *_Nullable *_Nullable)videoViewOut {
    if (obj.materialType == VIDEO) {
        ADMNativeVideoView *videoView = [[ADMNativeVideoView alloc] initWithFrame:CGRectZero andObject:obj];
        videoView.videoDelegate = self;
        if (videoViewOut) {
            *videoViewOut = videoView;
        }
        return videoView;
    }
    if (mainImage) {
        UIImageView *mainImageView = [[UIImageView alloc] initWithImage:mainImage];
        mainImageView.contentMode = UIViewContentModeScaleAspectFill;
        mainImageView.clipsToBounds = YES;
        return mainImageView;
    }
    return nil;
}

- (void)adm_completeNativeLoadWithObject:(ADMNativeAdObject *)strongObj
                               iconImage:(nullable UIImage *)iconImage
                               mainImage:(nullable UIImage *)mainImage {
    if (self.invalidated || !strongObj) {
        return;
    }
    ADMNativeVideoView *videoView = nil;
    UIView *mediaView = [self adm_mediaViewForObject:strongObj mainImage:mainImage videoViewOut:&videoView];
    CGFloat aspect = strongObj.aspectRatio > 0 ? strongObj.aspectRatio : 1.91f;
    UIViewController *presenter = self.presentingViewController;
    MANativeAdImage *iconNative = [self adm_nativeImageWithImage:iconImage urlString:strongObj.iconImageURLString];
    MANativeAdImage *mainNative = nil;
    if (strongObj.materialType != VIDEO) {
        mainNative = [self adm_nativeImageWithImage:mainImage urlString:strongObj.mainImageURLString];
    }

    ALAdMasterNativeAd *maxNative = [[ALAdMasterNativeAd alloc] initWithNativeAdObject:strongObj
                                                                             videoView:videoView
                                                              presentingViewController:presenter
                                                                          builderBlock:^(MANativeAdBuilder *builder) {
        builder.title = strongObj.title;
        builder.body = strongObj.text;
        builder.callToAction = strongObj.actButtonString;
        builder.advertiser = strongObj.brandName;
        builder.icon = iconNative;
        builder.mainImage = mainNative;
        builder.mediaView = mediaView;
        builder.mediaContentAspectRatio = aspect;
    }];
    [self.biddingReporter reportBidWinForAd:strongObj];
    [self.delegate didLoadAdForNativeAd:maxNative withExtraInfo:nil];
}

- (void)adm_finishNativeLoadWithObject:(ADMNativeAdObject *)obj {
    obj.interactionDelegate = self;
    dispatch_group_t group = dispatch_group_create();
    __block UIImage *iconImage = nil;
    __block UIImage *mainImage = nil;

    dispatch_group_enter(group);
    [self loadImageFromURLString:obj.iconImageURLString nativeAdObject:obj completion:^(UIImage *image) {
        iconImage = image;
        dispatch_group_leave(group);
    }];

    if (obj.materialType != VIDEO) {
        dispatch_group_enter(group);
        [self loadImageFromURLString:obj.mainImageURLString nativeAdObject:obj completion:^(UIImage *image) {
            mainImage = image;
            dispatch_group_leave(group);
        }];
    }

    __weak typeof(self) weakSelf = self;
    __weak ADMNativeAdObject *weakObj = obj;
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        ADMNativeAdObject *strongObj = weakObj;
        [strongSelf adm_completeNativeLoadWithObject:strongObj iconImage:iconImage mainImage:mainImage];
    });
}

- (void)nativeAdLoader:(ADMNativeAdLoader *)loader
didFailToReceiveAdWithError:(NSError *)error
        nativeAdObject:(nullable ADMNativeAdObject *)adObject {
    MAAdapterError *err = ADMMaxAdapterErrorFromNSError(error);
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.invalidated) {
            return;
        }
        [self.parent log:@"AdMaster native load failed: %@", error.localizedDescription];
        [self.biddingReporter reportBidLossForAd:(adObject ?: (id)(loader ?: self.targetLoader)) error:error];
        [self.delegate didFailToLoadNativeAdWithError:err];
    });
}

- (void)nativeAd:(ADMNativeAdObject *)ad didRecordClickForView:(UIView *)view {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.invalidated) {
            return;
        }
        [self.delegate didClickNativeAd];
    });
}

- (void)nativeAd:(ADMNativeAdObject *)ad didDismissLandingPageFromView:(UIView *)view {
}

- (void)nativeAd:(ADMNativeAdObject *)ad didRecordImpressionForView:(UIView *)view {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.invalidated) {
            return;
        }
        [self.biddingReporter reportBidWinForAd:ad];
        [self.delegate didDisplayNativeAdWithExtraInfo:nil];
    });
}

- (void)nativeAd:(ADMNativeAdObject *)ad didFailToRecordImpressionForView:(UIView *)view error:(NSError *)error {
    // MANativeAdAdapterDelegate only defines load/display success and click — no impression-fail callback.
    [self.parent log:@"AdMaster native impression failed: %@", error.localizedDescription];
}

#pragma mark - ADMNativeVideoViewDelegate

- (void)nativeVideoAdDidStartPlaying:(ADMNativeVideoView *)videoView {
}

- (void)nativeVideoAdDidPause:(ADMNativeVideoView *)videoView {
}

- (void)nativeVideoAdDidReplay:(ADMNativeVideoView *)videoView {
}

- (void)nativeVideoAdDidComplete:(ADMNativeVideoView *)videoView {
}

@end

#pragma mark - ALAdMasterMediationAdapter

@implementation ALAdMasterMediationAdapter

+ (void)initialize {
    [super initialize];
    if (self == [ALAdMasterMediationAdapter class]) {
        ALAdMasterInitLock = [[ALAtomicBoolean alloc] init];
    }
}

#pragma mark - Ad object factories

- (ADMInterstitialAd *)createInterstitialAd {
    return [[ADMInterstitialAd alloc] init];
}

- (ADMRewardedAd *)createRewardedAd {
    return [[ADMRewardedAd alloc] init];
}

- (ADMSplashAd *)createAppOpenAd {
    return [[ADMSplashAd alloc] init];
}

- (ADMBannerView *)createBannerViewWithSize:(CGSize)size adUnitTag:(NSString *)adUnitTag {
    return [[ADMBannerView alloc] initWithAdSize:size adUnitTag:adUnitTag];
}

- (ADMNativeAdLoader *)createNativeAdLoader {
    return [[ADMNativeAdLoader alloc] init];
}

#pragma mark - MAAdapter

- (void)initializeWithParameters:(id <MAAdapterInitializationParameters>)parameters
               completionHandler:(void (^)(MAAdapterInitializationStatus, NSString *_Nullable))completionHandler {
    NSString *appId = ADMMaxResolvedAppId(parameters);
    if (![appId al_isValidString]) {
        [self log:@"AdMaster init failed: missing app_id in MAX server parameters"];
        completionHandler(MAAdapterInitializationStatusInitializedFailure,
                          @"Missing app_id in MAX server parameters.");
        return;
    }
    [self log:@"AdMaster init with app_id=%@", appId];
    ADMMaxUpdateAdMasterRuntimeFromParameters(parameters);

    if ([ALAdMasterInitLock compareAndSet:NO update:YES]) {
        NSString *requestedAppId = [appId copy];
        __block NSUInteger gen = 0;
        @synchronized ([ALAdMasterMediationAdapter class]) {
            ALAdMasterInitStatus = MAAdapterInitializationStatusInitializing;
            ALAdMasterConfiguredAppId = requestedAppId;
            gen = ++ALAdMasterConfigGeneration;
        }
        __weak typeof(self) weakSelf = self;
        [ADMManager startWithAppsid:requestedAppId completionHandler:^(BOOL success, NSError *_Nullable error) {
            ADMMaxRunOnMain(^{
                MAAdapterInitializationStatus status;
                NSString *errorMessage = nil;
                @synchronized ([ALAdMasterMediationAdapter class]) {
                    status = success ? MAAdapterInitializationStatusInitializedSuccess : MAAdapterInitializationStatusInitializedFailure;
                    errorMessage = success ? nil : error.localizedDescription;
                    ALAdMasterInitStatus = status;
                    ALAdMasterInitErrorMessage = errorMessage;
                    if (!success &&
                        ALAdMasterConfigGeneration == gen &&
                        [ALAdMasterConfiguredAppId isEqualToString:requestedAppId]) {
                        ALAdMasterConfiguredAppId = nil;
                    }
                }
                if (!success) {
                    [weakSelf log:@"AdMaster SDK failed to initialize: %@", error];
                    [ALAdMasterInitLock compareAndSet:YES update:NO];
                }
                completionHandler(status, errorMessage);
            });
        }];
    } else {
        MAAdapterInitializationStatus status;
        NSString *errorMessage = nil;
        @synchronized ([ALAdMasterMediationAdapter class]) {
            status = ALAdMasterInitStatus;
            errorMessage = ALAdMasterInitErrorMessage;
        }
        completionHandler(status, errorMessage);
    }
}

- (NSString *)SDKVersion {
    return [ADMManager getSDKVersion] ?: @"";
}

- (NSString *)adapterVersion {
    return ADAPTER_VERSION;
}

- (void)teardownAppOpenLocked {
    if ([self.appOpenBridge isKindOfClass:[ALAdMasterAppOpenBridge class]]) {
        [(ALAdMasterAppOpenBridge *)self.appOpenBridge invalidate];
    }
    self.appOpenBridge = nil;
    if (self.appOpenAd) {
        [self.appOpenAd stop];
    }
    self.appOpenAd.delegate = nil;
    self.appOpenAd.fullScreenContentDelegate = nil;
    self.appOpenAd = nil;
}

- (void)teardownBannerLocked {
    if ([self.bannerBridge isKindOfClass:[ALAdMasterBannerBridge class]]) {
        [(ALAdMasterBannerBridge *)self.bannerBridge invalidate];
    }
    self.bannerBridge = nil;
    self.bannerView.delegate = nil;
    self.bannerView = nil;
}

- (void)teardownInterstitialLocked {
    if ([self.interstitialBridge isKindOfClass:[ALAdMasterInterstitialBridge class]]) {
        [(ALAdMasterInterstitialBridge *)self.interstitialBridge invalidate];
    }
    self.interstitialBridge = nil;
    self.interstitialAd.delegate = nil;
    self.interstitialAd.fullScreenContentDelegate = nil;
    self.interstitialAd = nil;
}

- (void)teardownRewardedLocked {
    if ([self.rewardedBridge isKindOfClass:[ALAdMasterRewardedBridge class]]) {
        [(ALAdMasterRewardedBridge *)self.rewardedBridge invalidate];
    }
    self.rewardedBridge = nil;
    self.rewardedAd.delegate = nil;
    self.rewardedAd.fullScreenContentDelegate = nil;
    self.rewardedAd = nil;
}

- (void)teardownNativeLocked {
    if ([self.nativeLoadSession isKindOfClass:[ALAdMasterNativeLoadSession class]]) {
        [(ALAdMasterNativeLoadSession *)self.nativeLoadSession invalidate];
    }
    self.nativeLoadSession = nil;
    self.nativeLoader.delegate = nil;
    self.nativeLoader = nil;
    self.nativePresentingViewController = nil;
}

- (void)invalidateAllBridgesLocked {
    if ([self.appOpenBridge isKindOfClass:[ALAdMasterAppOpenBridge class]]) {
        [(ALAdMasterAppOpenBridge *)self.appOpenBridge invalidate];
    }
    if ([self.bannerBridge isKindOfClass:[ALAdMasterBannerBridge class]]) {
        [(ALAdMasterBannerBridge *)self.bannerBridge invalidate];
    }
    if ([self.interstitialBridge isKindOfClass:[ALAdMasterInterstitialBridge class]]) {
        [(ALAdMasterInterstitialBridge *)self.interstitialBridge invalidate];
    }
    if ([self.rewardedBridge isKindOfClass:[ALAdMasterRewardedBridge class]]) {
        [(ALAdMasterRewardedBridge *)self.rewardedBridge invalidate];
    }
    if ([self.nativeLoadSession isKindOfClass:[ALAdMasterNativeLoadSession class]]) {
        [(ALAdMasterNativeLoadSession *)self.nativeLoadSession invalidate];
    }
}

- (void)destroy {
    @synchronized (self) {
        self.isDestroyed = YES;
        [self invalidateAllBridgesLocked];
    }
    ADMMaxRunOnMain(^{
        @synchronized (self) {
            [self log:@"Destroy called for adapter %@", self];
            [self teardownAppOpenLocked];
            [self teardownBannerLocked];
            [self teardownInterstitialLocked];
            [self teardownRewardedLocked];
            [self teardownNativeLocked];
        }
    });
}

#pragma mark - Shared helpers

- (nullable UIViewController *)presentingViewControllerFromParameters:(id <MAAdapterResponseParameters>)parameters {
    return parameters.presentingViewController ?: [ALUtils topViewControllerFromKeyWindow];
}

- (void)prepareRuntimeForParameters:(id <MAAdapterParameters>)parameters {
    ADMMaxUpdateAdMasterRuntimeFromParameters(parameters);
    NSString *appId = ADMMaxResolvedAppId(parameters);
    if ([appId al_isValidString]) {
        NSString *requestedAppId = [appId copy];
        __block NSUInteger gen = 0;
        __block BOOL shouldStart = NO;
        @synchronized ([ALAdMasterMediationAdapter class]) {
            if (![ALAdMasterConfiguredAppId isEqualToString:requestedAppId]) {
                ALAdMasterConfiguredAppId = requestedAppId;
                gen = ++ALAdMasterConfigGeneration;
                shouldStart = YES;
            }
        }
        if (shouldStart) {
            [ADMManager startWithAppsid:requestedAppId completionHandler:^(BOOL success, NSError *_Nullable error) {
                if (!success) {
                    @synchronized ([ALAdMasterMediationAdapter class]) {
                        if (ALAdMasterConfigGeneration == gen &&
                            [ALAdMasterConfiguredAppId isEqualToString:requestedAppId]) {
                            ALAdMasterConfiguredAppId = nil;
                        }
                    }
                }
            }];
        }
    }
}

- (ADMRequest *)requestFromParameters:(id <MAAdapterParameters>)parameters {
    ADMRequest *request = [ADMRequest defaultRequest];
    id rawBidFloor = ADMMaxRuntimeParameter(parameters, kADMMaxServerKeyBidFloor);
    NSInteger bidFloor = ADMMaxPositiveIntegerFromValue(rawBidFloor);
    request.bidFloor = (int)bidFloor;
    return request;
}

- (void)startLoadForTarget:(id <ADMMaxBiddingLoadable>)target
                parameters:(id <MAAdapterResponseParameters>)parameters
                  isBanner:(BOOL)isBanner {
    NSString *resolvedBid = ADMMaxResolvedBidResponse(parameters);
    if (resolvedBid.length > 0) {
        if (ADMMaxIsADMJsonPayload(resolvedBid)) {
            [target loadBiddingAdWithADMData:resolvedBid];
        } else {
            [target loadBiddingAdWithTokenId:resolvedBid];
        }
        return;
    }
    if (isBanner) {
        [target loadAd];
    } else {
        [target load];
    }
}

- (MAAdapterError *)missingPlacementError {
    return [MAAdapterError errorWithAdapterError:MAAdapterError.invalidConfiguration
                        mediatedNetworkErrorCode:-1
                     mediatedNetworkErrorMessage:@"Missing placement / ad_unit_id"];
}

#pragma mark - MASignalProvider

- (nullable NSString *)biddingTokenForParameters:(id <MASignalCollectionParameters>)parameters
                                       placement:(NSString *)placement
                                         request:(ADMRequest *)request {
    MAAdFormat *adFormat = parameters.adFormat;
    if (adFormat == MAAdFormat.interstitial) {
        ADMInterstitialAd *ad = [self createInterstitialAd];
        ad.adUnitTag = placement;
        ad.request = request;
        return [ad getBiddingToken];
    }
    if (adFormat == MAAdFormat.rewarded) {
        ADMRewardedAd *ad = [self createRewardedAd];
        ad.adUnitTag = placement;
        ad.request = request;
        return [ad getBiddingToken];
    }
    if (adFormat == MAAdFormat.appOpen) {
        ADMSplashAd *ad = [self createAppOpenAd];
        ad.adUnitTag = placement;
        ad.adSize = ADMMaxAppOpenAdSize();
        ad.request = request;
        return [ad getBiddingToken];
    }
    if (adFormat == MAAdFormat.banner || adFormat == MAAdFormat.leader || adFormat == MAAdFormat.mrec) {
        CGSize size = ADMMaxResolvedAdViewSize(parameters, adFormat);
        ADMBannerView *banner = [self createBannerViewWithSize:size adUnitTag:placement];
        banner.request = request;
        return [banner getBiddingToken];
    }
    if (adFormat == MAAdFormat.native) {
        ADMNativeAdLoader *loader = [self createNativeAdLoader];
        loader.adUnitTag = placement;
        loader.request = request;
        return [loader getBiddingToken];
    }
    return nil;
}

- (void)collectSignalWithParameters:(id <MASignalCollectionParameters>)parameters
                          andNotify:(id <MASignalCollectionDelegate>)delegate {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        @synchronized (self) {
            if (self.isDestroyed) {
                [delegate didFailToCollectSignalWithErrorMessage:@"Adapter is destroyed"];
                return;
            }
            [self prepareRuntimeForParameters:parameters];
            NSString *placement = ADMMaxResolvedPlacementId(parameters);
            if (![placement al_isValidString]) {
                [self log:@"AdMaster collectSignal failed: missing placement / ad_unit_id"];
                [delegate didFailToCollectSignalWithErrorMessage:@"Missing placement / ad_unit_id"];
                return;
            }
            ADMRequest *request = [self requestFromParameters:parameters];
            NSString *token = [self biddingTokenForParameters:parameters
                                                    placement:placement
                                                      request:request];
            if (![token al_isValidString]) {
                [self log:@"AdMaster collectSignal failed: empty bidding token"];
                [delegate didFailToCollectSignalWithErrorMessage:@"Failed to collect bidding token"];
                return;
            }
            [delegate didCollectSignal:token];
        }
    });
}

#pragma mark - MAInterstitialAdapter

- (void)loadInterstitialAdForParameters:(id <MAAdapterResponseParameters>)parameters
                              andNotify:(id <MAInterstitialAdapterDelegate>)delegate {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        @synchronized (self) {
            if (self.isDestroyed) {
                return;
            }
            [self prepareRuntimeForParameters:parameters];
            NSString *placement = ADMMaxResolvedPlacementId(parameters);
            if (![placement al_isValidString]) {
                [self log:@"Abort interstitial load: missing placement / ad_unit_id"];
                [delegate didFailToLoadInterstitialAdWithError:[self missingPlacementError]];
                return;
            }

            [self teardownInterstitialLocked];

            ALAdMasterBiddingReporter *reporter = [[ALAdMasterBiddingReporter alloc] initWithParameters:parameters];
            ALAdMasterInterstitialBridge *bridge = [[ALAdMasterInterstitialBridge alloc] initWithParent:self
                                                                                               delegate:delegate
                                                                                        biddingReporter:reporter];
            ADMInterstitialAd *ad = [self createInterstitialAd];
            bridge.targetAd = ad;
            self.interstitialBridge = bridge;
            self.interstitialAd = ad;
            ad.adUnitTag = placement;
            ad.request = [self requestFromParameters:parameters];
            ad.delegate = bridge;
            ad.fullScreenContentDelegate = bridge;
            [self startLoadForTarget:(id <ADMMaxBiddingLoadable>)ad
                          parameters:parameters
                            isBanner:NO];
        }
    });
}

- (void)showInterstitialAdForParameters:(id <MAAdapterResponseParameters>)parameters
                              andNotify:(id <MAInterstitialAdapterDelegate>)delegate {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        @synchronized (self) {
            if (self.isDestroyed) {
                return;
            }
            if ([self.interstitialBridge isKindOfClass:[ALAdMasterInterstitialBridge class]]) {
                ((ALAdMasterInterstitialBridge *)self.interstitialBridge).delegate = delegate;
            }
            if (!self.interstitialAd || ![self.interstitialAd isReady]) {
                [self log:@"AdMaster interstitial show failed: ad not ready"];
                MAAdapterError *error = [MAAdapterError errorWithAdapterError:MAAdapterError.adDisplayFailedError
                                                     mediatedNetworkErrorCode:MAAdapterError.adNotReady.code
                                                  mediatedNetworkErrorMessage:MAAdapterError.adNotReady.message];
                [delegate didFailToDisplayInterstitialAdWithError:error];
                return;
            }
            UIViewController *presentingViewController = [self presentingViewControllerFromParameters:parameters];
            if (!presentingViewController) {
                [self log:@"AdMaster interstitial show failed: no presenting view controller"];
                MAAdapterError *error = [MAAdapterError errorWithAdapterError:MAAdapterError.adDisplayFailedError
                                                     mediatedNetworkErrorCode:-1
                                                  mediatedNetworkErrorMessage:@"No presenting view controller"];
                [delegate didFailToDisplayInterstitialAdWithError:error];
                return;
            }
            [self.interstitialAd presentFromViewController:presentingViewController];
        }
    });
}

#pragma mark - MARewardedAdapter

- (void)loadRewardedAdForParameters:(id <MAAdapterResponseParameters>)parameters
                          andNotify:(id <MARewardedAdapterDelegate>)delegate {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        @synchronized (self) {
            if (self.isDestroyed) {
                return;
            }
            [self prepareRuntimeForParameters:parameters];
            NSString *placement = ADMMaxResolvedPlacementId(parameters);
            if (![placement al_isValidString]) {
                [self log:@"Abort rewarded load: missing placement / ad_unit_id"];
                [delegate didFailToLoadRewardedAdWithError:[self missingPlacementError]];
                return;
            }

            [self teardownRewardedLocked];

            ALAdMasterBiddingReporter *reporter = [[ALAdMasterBiddingReporter alloc] initWithParameters:parameters];
            ALAdMasterRewardedBridge *bridge = [[ALAdMasterRewardedBridge alloc] initWithParent:self
                                                                                       delegate:delegate
                                                                                biddingReporter:reporter];
            ADMRewardedAd *ad = [self createRewardedAd];
            bridge.targetAd = ad;
            self.rewardedBridge = bridge;
            self.rewardedAd = ad;
            ad.adUnitTag = placement;
            ad.request = [self requestFromParameters:parameters];
            ad.delegate = bridge;
            ad.fullScreenContentDelegate = bridge;
            [self startLoadForTarget:(id <ADMMaxBiddingLoadable>)ad
                          parameters:parameters
                            isBanner:NO];
        }
    });
}

- (void)showRewardedAdForParameters:(id <MAAdapterResponseParameters>)parameters
                          andNotify:(id <MARewardedAdapterDelegate>)delegate {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        @synchronized (self) {
            if (self.isDestroyed) {
                return;
            }
            if (!self.rewardedAd || ![self.rewardedAd isReady]) {
                [self log:@"AdMaster rewarded show failed: ad not ready"];
                MAAdapterError *error = [MAAdapterError errorWithAdapterError:MAAdapterError.adDisplayFailedError
                                                     mediatedNetworkErrorCode:MAAdapterError.adNotReady.code
                                                  mediatedNetworkErrorMessage:MAAdapterError.adNotReady.message];
                [delegate didFailToDisplayRewardedAdWithError:error];
                return;
            }
            UIViewController *presentingViewController = [self presentingViewControllerFromParameters:parameters];
            if (!presentingViewController) {
                [self log:@"AdMaster rewarded show failed: no presenting view controller"];
                MAAdapterError *error = [MAAdapterError errorWithAdapterError:MAAdapterError.adDisplayFailedError
                                                     mediatedNetworkErrorCode:-1
                                                  mediatedNetworkErrorMessage:@"No presenting view controller"];
                [delegate didFailToDisplayRewardedAdWithError:error];
                return;
            }
            if ([self.rewardedBridge isKindOfClass:[ALAdMasterRewardedBridge class]]) {
                ((ALAdMasterRewardedBridge *)self.rewardedBridge).delegate = delegate;
            }
            [self configureRewardForParameters:parameters];
            [self.rewardedAd presentFromViewController:presentingViewController];
        }
    });
}

#pragma mark - MAAdViewAdapter

- (void)loadAdViewAdForParameters:(id <MAAdapterResponseParameters>)parameters
                         adFormat:(MAAdFormat *)adFormat
                        andNotify:(id <MAAdViewAdapterDelegate>)delegate {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        @synchronized (self) {
            if (self.isDestroyed) {
                return;
            }
            [self prepareRuntimeForParameters:parameters];
            NSString *formatLabel = ADMMaxAdViewFormatLabel(adFormat);
            NSString *placement = ADMMaxResolvedPlacementId(parameters);
            if (![placement al_isValidString]) {
                [self log:@"Abort %@ load: missing placement / ad_unit_id", formatLabel];
                [delegate didFailToLoadAdViewAdWithError:[self missingPlacementError]];
                return;
            }

            CGSize size = ADMMaxResolvedAdViewSize(parameters, adFormat);
            [self teardownBannerLocked];

            ALAdMasterBiddingReporter *reporter = [[ALAdMasterBiddingReporter alloc] initWithParameters:parameters];
            ALAdMasterBannerBridge *bridge = [[ALAdMasterBannerBridge alloc] initWithParent:self
                                                                                   delegate:delegate
                                                                                formatLabel:formatLabel
                                                                            biddingReporter:reporter];
            ADMBannerView *banner = [self createBannerViewWithSize:size adUnitTag:placement];
            bridge.targetAd = banner;
            self.bannerBridge = bridge;
            self.bannerView = banner;
            banner.request = [self requestFromParameters:parameters];
            banner.delegate = bridge;
            [self startLoadForTarget:(id <ADMMaxBiddingLoadable>)banner
                          parameters:parameters
                            isBanner:YES];
        }
    });
}

#pragma mark - MANativeAdAdapter

- (void)loadNativeAdForParameters:(id <MAAdapterResponseParameters>)parameters
                        andNotify:(id <MANativeAdAdapterDelegate>)delegate {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        @synchronized (self) {
            if (self.isDestroyed) {
                return;
            }
            [self prepareRuntimeForParameters:parameters];
            NSString *placement = ADMMaxResolvedPlacementId(parameters);
            if (![placement al_isValidString]) {
                [self log:@"Abort native load: missing placement / ad_unit_id"];
                [delegate didFailToLoadNativeAdWithError:[self missingPlacementError]];
                return;
            }

            [self teardownNativeLocked];

            ALAdMasterBiddingReporter *reporter = [[ALAdMasterBiddingReporter alloc] initWithParameters:parameters];
            ALAdMasterNativeLoadSession *session = [[ALAdMasterNativeLoadSession alloc] initWithParent:self
                                                                                              delegate:delegate
                                                                                       biddingReporter:reporter];
            session.presentingViewController = parameters.presentingViewController;
            ADMNativeAdLoader *loader = [self createNativeAdLoader];
            session.targetLoader = loader;
            self.nativeLoadSession = session;
            self.nativeLoader = loader;
            loader.adUnitTag = placement;
            loader.request = [self requestFromParameters:parameters];
            loader.delegate = session;
            [self startLoadForTarget:(id <ADMMaxBiddingLoadable>)loader
                          parameters:parameters
                            isBanner:NO];
        }
    });
}

#pragma mark - MAAppOpenAdapter

- (void)loadAppOpenAdForParameters:(id <MAAdapterResponseParameters>)parameters
                         andNotify:(id <MAAppOpenAdapterDelegate>)delegate {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        @synchronized (self) {
            if (self.isDestroyed) {
                return;
            }
            [self prepareRuntimeForParameters:parameters];
            NSString *placement = ADMMaxResolvedPlacementId(parameters);
            if (![placement al_isValidString]) {
                [self log:@"Abort app open load: missing placement / ad_unit_id"];
                [delegate didFailToLoadAppOpenAdWithError:[self missingPlacementError]];
                return;
            }

            [self teardownAppOpenLocked];

            ALAdMasterBiddingReporter *reporter = [[ALAdMasterBiddingReporter alloc] initWithParameters:parameters];
            ALAdMasterAppOpenBridge *bridge = [[ALAdMasterAppOpenBridge alloc] initWithParent:self
                                                                                     delegate:delegate
                                                                              biddingReporter:reporter];
            ADMSplashAd *splash = [self createAppOpenAd];
            bridge.targetAd = splash;
            self.appOpenBridge = bridge;
            splash.delegate = bridge;
            splash.fullScreenContentDelegate = bridge;
            splash.adUnitTag = placement;
            splash.request = [self requestFromParameters:parameters];
            splash.adSize = ADMMaxAppOpenAdSize();
            splash.presentAdViewController = parameters.presentingViewController;
            self.appOpenAd = splash;
            [self startLoadForTarget:(id <ADMMaxBiddingLoadable>)splash
                          parameters:parameters
                            isBanner:NO];
        }
    });
}

- (void)showAppOpenAdForParameters:(id <MAAdapterResponseParameters>)parameters
                         andNotify:(id <MAAppOpenAdapterDelegate>)delegate {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        @synchronized (self) {
            if (self.isDestroyed) {
                return;
            }
            if ([self.appOpenBridge isKindOfClass:[ALAdMasterAppOpenBridge class]]) {
                ((ALAdMasterAppOpenBridge *)self.appOpenBridge).delegate = delegate;
                ((ALAdMasterAppOpenBridge *)self.appOpenBridge).didReportDisplay = NO;
            }
            if (!self.appOpenAd || ![self.appOpenAd isReady]) {
                [self log:@"AdMaster app open show failed: ad not ready"];
                MAAdapterError *error = [MAAdapterError errorWithAdapterError:MAAdapterError.adDisplayFailedError
                                                     mediatedNetworkErrorCode:MAAdapterError.adNotReady.code
                                                  mediatedNetworkErrorMessage:MAAdapterError.adNotReady.message];
                [delegate didFailToDisplayAppOpenAdWithError:error];
                return;
            }
            UIWindow *keyWindow = ADMMaxKeyWindow();
            if (!keyWindow) {
                [self log:@"AdMaster app open show failed: no key window"];
                MAAdapterError *error = [MAAdapterError errorWithAdapterError:MAAdapterError.adDisplayFailedError
                                                     mediatedNetworkErrorCode:-1
                                                  mediatedNetworkErrorMessage:@"No key window"];
                [delegate didFailToDisplayAppOpenAdWithError:error];
                return;
            }
            UIViewController *presentingViewController = [self presentingViewControllerFromParameters:parameters];
            self.appOpenAd.presentAdViewController = presentingViewController;
            self.appOpenAd.adSize = keyWindow.bounds.size;
            [self log:@"AdMaster app open showing."];
            [self.appOpenAd presentInContainerView:keyWindow presentingViewController:presentingViewController];
        }
    });
}

@end

NS_ASSUME_NONNULL_END
