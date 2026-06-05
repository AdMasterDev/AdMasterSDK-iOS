//
//  ALAdMasterMediationAdapter.m
//  Mediation/MAX
//

#import "ALAdMasterMediationAdapter.h"
#import "ALAdMasterNativeAd.h"
#import <AdMasterSDK/AdMasterSDK.h>
#import <AppLovinSDK/AppLovinSDK.h>

#define ADAPTER_VERSION @"2.0.1.0"

static NSString *const kADMMaxServerKeyAppId = @"app_id";
static NSString *const kADMMaxServerKeyAdUnitId = @"ad_unit_id";
static NSString *const kADMMaxServerKeyCustomParameters = @"custom_parameters";
static NSString *const kADMMaxServerKeyTest = @"test";
static NSString *const kADMMaxServerKeyMock = @"mock";
static NSString *const kADMMaxServerKeyWidth = @"width";
static NSString *const kADMMaxServerKeyHeight = @"height";
static NSString *const kADMMaxServerKeyBannerWidth = @"banner_width";
static NSString *const kADMMaxServerKeyBannerHeight = @"banner_height";

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

static id _Nullable ADMMaxServerParameter(id<MAAdapterParameters> parameters, NSString *key) {
    return parameters.serverParameters[key];
}

static id _Nullable ADMMaxCustomParameter(id<MAAdapterParameters> parameters, NSString *key) {
    id customValue = parameters.customParameters[key];
    if (customValue != nil) {
        return customValue;
    }
    NSDictionary *serverCustomParameters = ADMMaxDictionaryFromObject(ADMMaxServerParameter(parameters, kADMMaxServerKeyCustomParameters));
    return serverCustomParameters[key];
}

static id _Nullable ADMMaxRuntimeParameter(id<MAAdapterParameters> parameters, NSString *key) {
    id customValue = ADMMaxCustomParameter(parameters, key);
    if (customValue != nil) {
        return customValue;
    }
    return ADMMaxServerParameter(parameters, key);
}

static NSString *_Nullable ADMMaxResolvedAppId(id<MAAdapterInitializationParameters> parameters) {
    NSString *appId = ADMMaxStringFromObject(ADMMaxServerParameter((id<MAAdapterParameters>)parameters, kADMMaxServerKeyAppId));
    if (appId.length > 0) {
        return appId;
    }
    return nil;
}

static NSString *_Nullable ADMMaxResolvedPlacementId(id<MAAdapterResponseParameters> parameters) {
    if ([parameters.thirdPartyAdPlacementIdentifier al_isValidString]) {
        return parameters.thirdPartyAdPlacementIdentifier;
    }
    return ADMMaxStringFromObject(ADMMaxServerParameter(parameters, kADMMaxServerKeyAdUnitId));
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

static NSURL *_Nullable ADMMaxURLWithString(NSString *string) {
    if (string.length == 0) {
        return nil;
    }
    NSURL *url = [NSURL URLWithString:string];
    if (!url) {
        NSString *encodedString = [string stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        url = [NSURL URLWithString:encodedString];
    }
    return url;
}

static void ADMMaxUpdateAdMasterRuntimeFromParameters(id<MAAdapterParameters> parameters) {
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

static MAAdapterError *ADMMaxBiddingNotSupportedError(void) {
    return [MAAdapterError errorWithAdapterError:MAAdapterError.invalidLoadState
                        mediatedNetworkErrorCode:-44001
                     mediatedNetworkErrorMessage:@"AdMaster MAX adapter does not support bidding (bidResponse) loads."];
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

static CGSize ADMMaxResolvedAdViewSize(id<MAAdapterResponseParameters> parameters, MAAdFormat *adFormat) {
    CGSize size = ADMMaxDefaultAdViewSize(adFormat);
    CGFloat width = ADMMaxCGFloatFromServerValue(ADMMaxServerParameter(parameters, kADMMaxServerKeyBannerWidth));
    CGFloat height = ADMMaxCGFloatFromServerValue(ADMMaxServerParameter(parameters, kADMMaxServerKeyBannerHeight));
    if (width <= 0) {
        width = ADMMaxCGFloatFromServerValue(ADMMaxServerParameter(parameters, kADMMaxServerKeyWidth));
    }
    if (height <= 0) {
        height = ADMMaxCGFloatFromServerValue(ADMMaxServerParameter(parameters, kADMMaxServerKeyHeight));
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

#pragma mark - Forward declarations

@interface ALAdMasterMediationAdapter ()
@property (nonatomic, strong) ADMSplashAd *appOpenAd;
@property (nonatomic, strong) ADMBannerView *bannerView;
@property (nonatomic, strong) ADMInterstitialAd *interstitialAd;
@property (nonatomic, strong) ADMRewardedAd *rewardedAd;
@property (nonatomic, strong) ADMNativeAdLoader *nativeLoader;

@property (nonatomic, strong) NSObject *appOpenBridge;
@property (nonatomic, strong) NSObject *bannerBridge;
@property (nonatomic, strong) NSObject *interstitialBridge;
@property (nonatomic, strong) NSObject *rewardedBridge;
@property (nonatomic, strong) NSObject *nativeLoadSession;

@property (nonatomic, weak, nullable) UIViewController *nativePresentingViewController;
@end

static ALAtomicBoolean *ALAdMasterInitLock;
static MAAdapterInitializationStatus ALAdMasterInitStatus = NSIntegerMin;
static NSString *_Nullable ALAdMasterInitErrorMessage = nil;

#pragma mark - App open bridge

@interface ALAdMasterAppOpenBridge : NSObject <ADMSplashDelegate, ADMFullScreenContentDelegate>
@property (nonatomic, weak) ALAdMasterMediationAdapter *parent;
@property (nonatomic, strong) id<MAAppOpenAdapterDelegate> delegate;
@property (nonatomic, assign) BOOL didNotifyLoad;
@property (nonatomic, assign) BOOL didReportDisplay;
@end

@implementation ALAdMasterAppOpenBridge

- (instancetype)initWithParent:(ALAdMasterMediationAdapter *)parent delegate:(id<MAAppOpenAdapterDelegate>)delegate {
    self = [super init];
    if (self) {
        _parent = parent;
        _delegate = delegate;
    }
    return self;
}

- (void)splashAd:(ADMSplashAd *)splashAd didFailToReceiveAdWithError:(NSError *)error {
    __weak typeof(self) weakSelf = self;
    MAAdapterError *adapterError = ADMMaxAdapterErrorFromNSError(error);
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        [self.parent log:@"AdMaster app open load failed: %@", error.localizedDescription];
        [self.delegate didFailToLoadAppOpenAdWithError:adapterError];
    });
}

- (void)splashAdDidReceiveAd:(ADMSplashAd *)splash {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.didNotifyLoad) {
            return;
        }
        if (![splash isReady]) {
            return;
        }
        self.didNotifyLoad = YES;
        [self.parent log:@"AdMaster app open loaded."];
        [self.delegate didLoadAppOpenAd];
    });
}

- (void)adWillPresentFullScreenContent:(ADMSplashAd *)splash {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.didReportDisplay) {
            return;
        }
        self.didReportDisplay = YES;
        [self.delegate didDisplayAppOpenAd];
    });
}

- (void)ad:(ADMSplashAd *)splash didFailToPresentFullScreenContentWithError:(NSError *)error {
    __weak typeof(self) weakSelf = self;
    MAAdapterError *adapterError = ADMMaxAdapterErrorFromNSError(error);
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        [self.parent log:@"AdMaster app open display failed: %@", error.localizedDescription];
        [self.delegate didFailToDisplayAppOpenAdWithError:adapterError];
    });
}

- (void)adDidRecordClick:(ADMSplashAd *)splash {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
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
        if (!self) {
            return;
        }
        [self.delegate didHideAppOpenAd];
    });
}

@end

#pragma mark - Banner bridge

@interface ALAdMasterBannerBridge : NSObject <ADMBannerDelegate>
@property (nonatomic, weak) ALAdMasterMediationAdapter *parent;
@property (nonatomic, strong) id<MAAdViewAdapterDelegate> delegate;
@property (nonatomic, copy) NSString *formatLabel;
@end

@implementation ALAdMasterBannerBridge

- (instancetype)initWithParent:(ALAdMasterMediationAdapter *)parent
                      delegate:(id<MAAdViewAdapterDelegate>)delegate
                   formatLabel:(NSString *)formatLabel {
    self = [super init];
    if (self) {
        _parent = parent;
        _delegate = delegate;
        _formatLabel = [formatLabel copy] ?: @"ad view";
    }
    return self;
}

- (void)bannerViewDidReceiveAd:(ADMBannerView *)bannerView {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        [self.parent log:@"AdMaster %@ loaded.", self.formatLabel];
        [self.delegate didLoadAdForAdView:bannerView];
    });
}

- (void)bannerView:(ADMBannerView *)bannerView didFailToReceiveAdWithError:(NSError *)error {
    __weak typeof(self) weakSelf = self;
    NSString *message = error.localizedDescription ?: @"Unknown ad view load error";
    MAAdapterError *adapterError = ADMMaxAdapterErrorFromNSError(error);
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
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
        if (!self) {
            return;
        }
        [self.parent log:@"AdMaster %@ display failed: %@", self.formatLabel, message];
        [self.delegate didFailToDisplayAdViewAdWithError:adapterError];
    });
}

- (void)bannerViewDidRecordImpression:(ADMBannerView *)bannerView {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        [self.delegate didDisplayAdViewAd];
    });
}

- (void)bannerViewDidRecordClick:(ADMBannerView *)bannerView {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
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
@property (nonatomic, weak) ALAdMasterMediationAdapter *parent;
@property (nonatomic, strong) id<MAInterstitialAdapterDelegate> delegate;
@property (nonatomic, assign) BOOL didNotifyLoad;
@property (nonatomic, assign) BOOL didReportDisplay;
@end

@implementation ALAdMasterInterstitialBridge

- (instancetype)initWithParent:(ALAdMasterMediationAdapter *)parent delegate:(id<MAInterstitialAdapterDelegate>)delegate {
    self = [super init];
    if (self) {
        _parent = parent;
        _delegate = delegate;
    }
    return self;
}

- (void)interstitialAdDidReceiveAd:(ADMInterstitialAd *)interstitial {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.didNotifyLoad) {
            return;
        }
        self.didNotifyLoad = YES;
        [self.parent log:@"AdMaster interstitial loaded."];
        [self.delegate didLoadInterstitialAd];
    });
}

- (void)interstitialAd:(ADMInterstitialAd *)interstitial didFailToReceiveAdWithError:(NSError *)error {
    __weak typeof(self) weakSelf = self;
    MAAdapterError *adapterError = ADMMaxAdapterErrorFromNSError(error);
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        [self.parent log:@"AdMaster interstitial load failed: %@", error.localizedDescription];
        [self.delegate didFailToLoadInterstitialAdWithError:adapterError];
    });
}

- (void)adWillPresentFullScreenContent:(ADMInterstitialAd *)interstitial {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        if (self.didReportDisplay) {
            return;
        }
        self.didReportDisplay = YES;
        [self.delegate didDisplayInterstitialAd];
    });
}

- (void)ad:(ADMInterstitialAd *)interstitial didFailToPresentFullScreenContentWithError:(NSError *)error {
    __weak typeof(self) weakSelf = self;
    MAAdapterError *adapterError = ADMMaxAdapterErrorFromNSError(error);
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        [self.delegate didFailToDisplayInterstitialAdWithError:adapterError];
    });
}

- (void)adWillDismissFullScreenContent:(ADMInterstitialAd *)interstitial {
}

- (void)adDidDismissFullScreenContent:(ADMInterstitialAd *)interstitial {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        [self.delegate didHideInterstitialAd];
    });
}

- (void)adDidRecordClick:(ADMInterstitialAd *)interstitial {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        [self.delegate didClickInterstitialAd];
    });
}

- (void)adDidRecordImpression:(ADMInterstitialAd *)interstitial {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        if (self.didReportDisplay) {
            return;
        }
        self.didReportDisplay = YES;
        [self.parent log:@"AdMaster interstitial impressed (display)."];
        [self.delegate didDisplayInterstitialAd];
    });
}

@end

#pragma mark - Rewarded bridge

@interface ALAdMasterRewardedBridge : NSObject <ADMRewardedDelegate, ADMFullScreenContentDelegate>
@property (nonatomic, weak) ALAdMasterMediationAdapter *parent;
@property (nonatomic, strong) id<MARewardedAdapterDelegate> delegate;
@property (nonatomic, assign) BOOL didNotifyLoad;
@property (nonatomic, assign) BOOL hasGrantedReward;
@property (nonatomic, assign) BOOL hasCalledDisplay;
@end

@implementation ALAdMasterRewardedBridge

- (instancetype)initWithParent:(ALAdMasterMediationAdapter *)parent delegate:(id<MARewardedAdapterDelegate>)delegate {
    self = [super init];
    if (self) {
        _parent = parent;
        _delegate = delegate;
    }
    return self;
}

- (void)rewardedAdDidReceiveAd:(ADMRewardedAd *)video {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.didNotifyLoad) {
            return;
        }
        self.didNotifyLoad = YES;
        [self.parent log:@"AdMaster rewarded loaded."];
        [self.delegate didLoadRewardedAd];
    });
}

- (void)rewardedAd:(ADMRewardedAd *)video didFailToReceiveAdWithError:(NSError *)error {
    __weak typeof(self) weakSelf = self;
    MAAdapterError *adapterError = ADMMaxAdapterErrorFromNSError(error);
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
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
        if (!self) {
            return;
        }
        [self.delegate didFailToDisplayRewardedAdWithError:adapterError];
    });
}

- (void)adWillPresentFullScreenContent:(ADMRewardedAd *)video {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        if (!self.hasCalledDisplay) {
            self.hasCalledDisplay = YES;
            [self.delegate didDisplayRewardedAd];
        }
    });
}

- (void)adDidRecordClick:(ADMRewardedAd *)video {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        [self.delegate didClickRewardedAd];
    });
}

- (void)adDidDismissFullScreenContent:(ADMRewardedAd *)video {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
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
        if (!self || self.hasGrantedReward) {
            return;
        }
        self.hasGrantedReward = YES;
        MAReward *reward = self.parent.reward ?: [MAReward rewardWithAmount:MAReward.defaultAmount label:@""];
        [self.delegate didRewardUserWithReward:reward];
    });
}

@end

#pragma mark - Native load session

@interface ALAdMasterNativeLoadSession : NSObject <ADMNativeAdLoaderDelegate, ADMNativeInteractionDelegate, ADMNativeVideoViewDelegate>
@property (nonatomic, weak) ALAdMasterMediationAdapter *parent;
@property (nonatomic, strong) id<MANativeAdAdapterDelegate> delegate;
@property (nonatomic, weak, nullable) UIViewController *presentingViewController;
@property (nonatomic, assign) BOOL invalidated;
@end

@implementation ALAdMasterNativeLoadSession

- (instancetype)initWithParent:(ALAdMasterMediationAdapter *)parent delegate:(id<MANativeAdAdapterDelegate>)delegate {
    self = [super init];
    if (self) {
        _parent = parent;
        _delegate = delegate;
    }
    return self;
}

- (void)invalidate {
    self.invalidated = YES;
}

- (void)loadImageFromURLString:(NSString *)urlString
               nativeAdObject:(ADMNativeAdObject *)nativeAdObject
                    completion:(void (^)(UIImage *_Nullable image))completion {
    if (self.invalidated || urlString.length == 0) {
        if (completion) {
            completion(nil);
        }
        return;
    }
    if (!nativeAdObject) {
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
        if (!self) {
            return;
        }
        [self.parent log:@"AdMaster native objects success. count=%lu", (unsigned long)nativeAds.count];
        if (!nativeAds.count || ![nativeAds.firstObject isKindOfClass:[ADMNativeAdObject class]]) {
            MAAdapterError *err = [MAAdapterError errorWithAdapterError:MAAdapterError.noFill
                                               mediatedNetworkErrorCode:-1
                                            mediatedNetworkErrorMessage:@"No native ad object"];
            [self.parent log:@"AdMaster native load failed: no valid ADMNativeAdObject"];
            [self.delegate didFailToLoadNativeAdWithError:err];
            return;
        }
        ADMNativeAdObject *obj = nativeAds.firstObject;
        if ([obj isExpired]) {
            MAAdapterError *err = [MAAdapterError errorWithAdapterError:MAAdapterError.adExpiredError
                                               mediatedNetworkErrorCode:-1
                                            mediatedNetworkErrorMessage:@"Native ad expired"];
            [self.delegate didFailToLoadNativeAdWithError:err];
            return;
        }
        [self adm_finishNativeLoadWithObject:obj];
    });
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
        if (!strongSelf || strongSelf.invalidated || !strongObj) {
            return;
        }
        
        ADMNativeVideoView *videoView = nil;
        UIView *mediaView = nil;
        if (strongObj.materialType == VIDEO) {
            videoView = [[ADMNativeVideoView alloc] initWithFrame:CGRectZero andObject:strongObj];
            videoView.videoDelegate = strongSelf;
            mediaView = videoView;
        }
        
        CGFloat aspect = strongObj.aspectRatio > 0 ? strongObj.aspectRatio : 1.91f;
        UIViewController *presenter = strongSelf.presentingViewController;
        
        MANativeAdImage *iconNative = nil;
        if (iconImage) {
            iconNative = [[MANativeAdImage alloc] initWithImage:iconImage];
        } else if (strongObj.iconImageURLString.length > 0) {
            NSURL *iconURL = ADMMaxURLWithString(strongObj.iconImageURLString);
            if (iconURL) {
                iconNative = [[MANativeAdImage alloc] initWithURL:iconURL];
            }
        }
        
        MANativeAdImage *mainNative = nil;
        if (strongObj.materialType != VIDEO) {
            if (mainImage) {
                mainNative = [[MANativeAdImage alloc] initWithImage:mainImage];
                UIImageView *mainImageView = [[UIImageView alloc] initWithImage:mainImage];
                mainImageView.contentMode = UIViewContentModeScaleAspectFill;
                mainImageView.clipsToBounds = YES;
                mediaView = mainImageView;
            } else if (strongObj.mainImageURLString.length > 0) {
                NSURL *mainURL = ADMMaxURLWithString(strongObj.mainImageURLString);
                if (mainURL) {
                    mainNative = [[MANativeAdImage alloc] initWithURL:mainURL];
                }
            }
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
        
        [strongSelf.delegate didLoadAdForNativeAd:maxNative withExtraInfo:nil];
    });
}

- (void)nativeAdLoader:(ADMNativeAdLoader *)loader
didFailToReceiveAdWithError:(NSError *)error
          nativeAdObject:(ADMNativeAdObject *)adObject {
    MAAdapterError *err = ADMMaxAdapterErrorFromNSError(error);
    [self.parent log:@"AdMaster native load failed: %@", error.localizedDescription];
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        [weakSelf.delegate didFailToLoadNativeAdWithError:err];
    });
}

- (void)nativeAd:(ADMNativeAdObject *)ad didRecordClickForView:(UIView *)view {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        [weakSelf.delegate didClickNativeAd];
    });
}

- (void)nativeAd:(ADMNativeAdObject *)ad didDismissLandingPageFromView:(UIView *)view {
}

- (void)nativeAd:(ADMNativeAdObject *)ad didRecordImpressionForView:(UIView *)view {
    __weak typeof(self) weakSelf = self;
    ADMMaxRunOnMain(^{
        [weakSelf.delegate didDisplayNativeAdWithExtraInfo:nil];
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

#pragma mark - MAAdapter

- (void)initializeWithParameters:(id<MAAdapterInitializationParameters>)parameters
               completionHandler:(void (^)(MAAdapterInitializationStatus, NSString *_Nullable))completionHandler {
    NSString *appId = ADMMaxResolvedAppId(parameters);
    if (![appId al_isValidString]) {
        [self log:@"AdMaster init failed: missing app_id in MAX server parameters"];
        completionHandler(MAAdapterInitializationStatusInitializedFailure, @"Missing app_id in MAX server parameters.");
        return;
    }
    [self log:@"AdMaster init with app_id=%@", appId];
    
    ADMMaxUpdateAdMasterRuntimeFromParameters(parameters);
    
    if ([ALAdMasterInitLock compareAndSet:NO update:YES]) {
        ALAdMasterInitStatus = MAAdapterInitializationStatusInitializing;
        __weak typeof(self) weakSelf = self;
        [ADMManager startWithAppsid:appId completionHandler:^(BOOL success, NSError *_Nullable error) {
            ADMMaxRunOnMain(^{
                ALAdMasterInitStatus = success ? MAAdapterInitializationStatusInitializedSuccess
                : MAAdapterInitializationStatusInitializedFailure;
                ALAdMasterInitErrorMessage = success ? nil : error.localizedDescription;
                if (!success) {
                    [weakSelf log:@"AdMaster SDK failed to initialize: %@", error];
                    [ALAdMasterInitLock compareAndSet:YES update:NO];
                }
                completionHandler(ALAdMasterInitStatus, ALAdMasterInitErrorMessage);
            });
        }];
    } else {
        completionHandler(ALAdMasterInitStatus, ALAdMasterInitErrorMessage);
    }
}

- (NSString *)SDKVersion {
    return [ADMManager getSDKVersion] ?: @"";
}

- (NSString *)adapterVersion {
    return ADAPTER_VERSION;
}

- (void)destroy {
    [self log:@"Destroy called for adapter %@", self];
    
    if (self.appOpenAd) {
        [self.appOpenAd stop];
    }
    self.appOpenAd.delegate = nil;
    self.appOpenAd = nil;
    ((ALAdMasterAppOpenBridge *)self.appOpenBridge).delegate = nil;
    self.appOpenBridge = nil;
    
    self.bannerView.delegate = nil;
    self.bannerView = nil;
    ((ALAdMasterBannerBridge *)self.bannerBridge).delegate = nil;
    self.bannerBridge = nil;
    
    self.interstitialAd.delegate = nil;
    self.interstitialAd = nil;
    ((ALAdMasterInterstitialBridge *)self.interstitialBridge).delegate = nil;
    self.interstitialBridge = nil;
    
    self.rewardedAd.delegate = nil;
    self.rewardedAd = nil;
    ((ALAdMasterRewardedBridge *)self.rewardedBridge).delegate = nil;
    self.rewardedBridge = nil;
    
    self.nativeLoader.delegate = nil;
    self.nativeLoader = nil;
    if ([self.nativeLoadSession isKindOfClass:[ALAdMasterNativeLoadSession class]]) {
        [(ALAdMasterNativeLoadSession *)self.nativeLoadSession invalidate];
        ((ALAdMasterNativeLoadSession *)self.nativeLoadSession).delegate = nil;
    }
    self.nativeLoadSession = nil;
    
    self.nativePresentingViewController = nil;
}

#pragma mark - Shared helpers

- (UIViewController *)presentingViewControllerFromParameters:(id<MAAdapterResponseParameters>)parameters {
    return parameters.presentingViewController ?: [ALUtils topViewControllerFromKeyWindow];
}

#pragma mark - MAInterstitialAdapter

- (void)loadInterstitialAdForParameters:(id<MAAdapterResponseParameters>)parameters andNotify:(id<MAInterstitialAdapterDelegate>)delegate {
    if ([parameters.bidResponse al_isValidString]) {
        [delegate didFailToLoadInterstitialAdWithError:ADMMaxBiddingNotSupportedError()];
        return;
    }
    ADMMaxUpdateAdMasterRuntimeFromParameters(parameters);
    
    NSString *placement = ADMMaxResolvedPlacementId(parameters);
    if (![placement al_isValidString]) {
        [self log:@"Abort interstitial load: missing placement / ad_unit_id"];
        [delegate didFailToLoadInterstitialAdWithError:        [MAAdapterError errorWithAdapterError:MAAdapterError.invalidConfiguration
                                                                            mediatedNetworkErrorCode:-1
                                                                         mediatedNetworkErrorMessage:@"Missing placement / ad_unit_id"]];
        return;
    }
    
    self.interstitialAd.delegate = nil;
    self.interstitialAd = nil;
    self.interstitialBridge = nil;
    
    self.interstitialBridge = [[ALAdMasterInterstitialBridge alloc] initWithParent:self delegate:delegate];
    self.interstitialAd = [[ADMInterstitialAd alloc] init];
    self.interstitialAd.adUnitTag = placement;
    self.interstitialAd.delegate = (id<ADMInterstitialDelegate>)self.interstitialBridge;
    self.interstitialAd.fullScreenContentDelegate = (id<ADMFullScreenContentDelegate>)self.interstitialBridge;
    [self.interstitialAd load];
}

- (void)showInterstitialAdForParameters:(id<MAAdapterResponseParameters>)parameters andNotify:(id<MAInterstitialAdapterDelegate>)delegate {
    if ([self.interstitialBridge isKindOfClass:[ALAdMasterInterstitialBridge class]]) {
        ((ALAdMasterInterstitialBridge *)self.interstitialBridge).delegate = delegate;
    }
    if (!self.interstitialAd) {
        [self log:@"AdMaster interstitial show failed: no loaded ad"];
        MAAdapterError *error = [MAAdapterError errorWithAdapterError:MAAdapterError.adDisplayFailedError
                                             mediatedNetworkErrorCode:MAAdapterError.adNotReady.code
                                          mediatedNetworkErrorMessage:MAAdapterError.adNotReady.message];
        [delegate didFailToDisplayInterstitialAdWithError:error];
        return;
    }
    UIViewController *presentingViewController = [self presentingViewControllerFromParameters:parameters];
    if (![self.interstitialAd isReady]) {
        [self log:@"AdMaster interstitial show failed: ad not ready"];
        MAAdapterError *error = [MAAdapterError errorWithAdapterError:MAAdapterError.adDisplayFailedError
                                             mediatedNetworkErrorCode:MAAdapterError.adNotReady.code
                                          mediatedNetworkErrorMessage:MAAdapterError.adNotReady.message];
        [delegate didFailToDisplayInterstitialAdWithError:error];
        return;
    }
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

#pragma mark - MARewardedAdapter

- (void)loadRewardedAdForParameters:(id<MAAdapterResponseParameters>)parameters andNotify:(id<MARewardedAdapterDelegate>)delegate {
    if ([parameters.bidResponse al_isValidString]) {
        [delegate didFailToLoadRewardedAdWithError:ADMMaxBiddingNotSupportedError()];
        return;
    }
    ADMMaxUpdateAdMasterRuntimeFromParameters(parameters);
    
    NSString *placement = ADMMaxResolvedPlacementId(parameters);
    if (![placement al_isValidString]) {
        [self log:@"Abort rewarded load: missing placement / ad_unit_id"];
        [delegate didFailToLoadRewardedAdWithError:        [MAAdapterError errorWithAdapterError:MAAdapterError.invalidConfiguration
                                                                        mediatedNetworkErrorCode:-1
                                                                     mediatedNetworkErrorMessage:@"Missing placement / ad_unit_id"]];
        return;
    }
    
    self.rewardedAd.delegate = nil;
    self.rewardedAd = nil;
    self.rewardedBridge = nil;
    
    ALAdMasterRewardedBridge *bridge = [[ALAdMasterRewardedBridge alloc] initWithParent:self delegate:delegate];
    self.rewardedBridge = bridge;
    self.rewardedAd = [[ADMRewardedAd alloc] init];
    self.rewardedAd.adUnitTag = placement;
    self.rewardedAd.delegate = bridge;
    self.rewardedAd.fullScreenContentDelegate = bridge;
    [self.rewardedAd load];
}

- (void)showRewardedAdForParameters:(id<MAAdapterResponseParameters>)parameters andNotify:(id<MARewardedAdapterDelegate>)delegate {
    if (!self.rewardedAd) {
        [self log:@"AdMaster rewarded show failed: no loaded ad"];
        MAAdapterError *error = [MAAdapterError errorWithAdapterError:MAAdapterError.adDisplayFailedError
                                             mediatedNetworkErrorCode:MAAdapterError.adNotReady.code
                                          mediatedNetworkErrorMessage:MAAdapterError.adNotReady.message];
        [delegate didFailToDisplayRewardedAdWithError:error];
        return;
    }
    UIViewController *presentingViewController = [self presentingViewControllerFromParameters:parameters];
    if (![self.rewardedAd isReady]) {
        [self log:@"AdMaster rewarded show failed: ad not ready"];
        MAAdapterError *error = [MAAdapterError errorWithAdapterError:MAAdapterError.adDisplayFailedError
                                             mediatedNetworkErrorCode:MAAdapterError.adNotReady.code
                                          mediatedNetworkErrorMessage:MAAdapterError.adNotReady.message];
        [delegate didFailToDisplayRewardedAdWithError:error];
        return;
    }
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

#pragma mark - MAAdViewAdapter

- (void)loadAdViewAdForParameters:(id<MAAdapterResponseParameters>)parameters
                         adFormat:(MAAdFormat *)adFormat
                        andNotify:(id<MAAdViewAdapterDelegate>)delegate {
    if ([parameters.bidResponse al_isValidString]) {
        [delegate didFailToLoadAdViewAdWithError:ADMMaxBiddingNotSupportedError()];
        return;
    }
    ADMMaxUpdateAdMasterRuntimeFromParameters(parameters);
    
    NSString *formatLabel = ADMMaxAdViewFormatLabel(adFormat);
    NSString *placement = ADMMaxResolvedPlacementId(parameters);
    if (![placement al_isValidString]) {
        [self log:@"Abort %@ load: missing placement / ad_unit_id", formatLabel];
        [delegate didFailToLoadAdViewAdWithError:        [MAAdapterError errorWithAdapterError:MAAdapterError.invalidConfiguration
                                                                      mediatedNetworkErrorCode:-1
                                                                   mediatedNetworkErrorMessage:@"Missing placement / ad_unit_id"]];
        return;
    }
    
    CGSize size = ADMMaxResolvedAdViewSize(parameters, adFormat);
    
    self.bannerView.delegate = nil;
    self.bannerView = nil;
    self.bannerBridge = nil;
    
    self.bannerBridge = [[ALAdMasterBannerBridge alloc] initWithParent:self delegate:delegate formatLabel:formatLabel];
    self.bannerView = [[ADMBannerView alloc] initWithAdSize:size adUnitTag:placement];
    self.bannerView.delegate = (id<ADMBannerDelegate>)self.bannerBridge;
    [self.bannerView loadAd];
}

#pragma mark - MANativeAdAdapter

- (void)loadNativeAdForParameters:(id<MAAdapterResponseParameters>)parameters andNotify:(id<MANativeAdAdapterDelegate>)delegate {
    if ([parameters.bidResponse al_isValidString]) {
        [delegate didFailToLoadNativeAdWithError:ADMMaxBiddingNotSupportedError()];
        return;
    }
    ADMMaxUpdateAdMasterRuntimeFromParameters(parameters);
    
    NSString *placement = ADMMaxResolvedPlacementId(parameters);
    if (![placement al_isValidString]) {
        [self log:@"Abort native load: missing placement / ad_unit_id"];
        [delegate didFailToLoadNativeAdWithError:        [MAAdapterError errorWithAdapterError:MAAdapterError.invalidConfiguration
                                                                      mediatedNetworkErrorCode:-1
                                                                   mediatedNetworkErrorMessage:@"Missing placement / ad_unit_id"]];
        return;
    }
    
    self.nativeLoader.delegate = nil;
    self.nativeLoader = nil;
    self.nativeLoadSession = nil;
    
    ALAdMasterNativeLoadSession *session = [[ALAdMasterNativeLoadSession alloc] initWithParent:self delegate:delegate];
    session.presentingViewController = parameters.presentingViewController;
    self.nativeLoadSession = session;
    
    self.nativeLoader = [[ADMNativeAdLoader alloc] init];
    self.nativeLoader.adUnitTag = placement;
    self.nativeLoader.delegate = session;
    [self.nativeLoader load];
}

#pragma mark - MAAppOpenAdapter

- (void)loadAppOpenAdForParameters:(id<MAAdapterResponseParameters>)parameters andNotify:(id<MAAppOpenAdapterDelegate>)delegate {
    if ([parameters.bidResponse al_isValidString]) {
        [delegate didFailToLoadAppOpenAdWithError:ADMMaxBiddingNotSupportedError()];
        return;
    }
    ADMMaxUpdateAdMasterRuntimeFromParameters(parameters);
    
    NSString *placement = ADMMaxResolvedPlacementId(parameters);
    if (![placement al_isValidString]) {
        [self log:@"Abort app open load: missing placement / ad_unit_id"];
        [delegate didFailToLoadAppOpenAdWithError:        [MAAdapterError errorWithAdapterError:MAAdapterError.invalidConfiguration
                                                                       mediatedNetworkErrorCode:-1
                                                                    mediatedNetworkErrorMessage:@"Missing placement / ad_unit_id"]];
        return;
    }
    
    if (self.appOpenAd) {
        [self.appOpenAd stop];
    }
    self.appOpenAd.delegate = nil;
    self.appOpenAd = nil;
    self.appOpenBridge = nil;
    
    ALAdMasterAppOpenBridge *bridge = [[ALAdMasterAppOpenBridge alloc] initWithParent:self delegate:delegate];
    self.appOpenBridge = bridge;
    
    ADMSplashAd *splash = [[ADMSplashAd alloc] init];
    splash.delegate = bridge;
    splash.fullScreenContentDelegate = bridge;
    splash.adUnitTag = placement;
    splash.adSize = ADMMaxAppOpenAdSize();
    splash.presentAdViewController = parameters.presentingViewController;
    self.appOpenAd = splash;
    
    [self.appOpenAd load];
}

- (void)showAppOpenAdForParameters:(id<MAAdapterResponseParameters>)parameters andNotify:(id<MAAppOpenAdapterDelegate>)delegate {
    if ([self.appOpenBridge isKindOfClass:[ALAdMasterAppOpenBridge class]]) {
        ((ALAdMasterAppOpenBridge *)self.appOpenBridge).delegate = delegate;
        ((ALAdMasterAppOpenBridge *)self.appOpenBridge).didReportDisplay = NO;
    }
    
    if (!self.appOpenAd) {
        [self log:@"AdMaster app open show failed: no loaded ad"];
        MAAdapterError *error = [MAAdapterError errorWithAdapterError:MAAdapterError.adDisplayFailedError
                                             mediatedNetworkErrorCode:MAAdapterError.adNotReady.code
                                          mediatedNetworkErrorMessage:MAAdapterError.adNotReady.message];
        [delegate didFailToDisplayAppOpenAdWithError:error];
        return;
    }
    
    if (![self.appOpenAd isReady]) {
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

@end
