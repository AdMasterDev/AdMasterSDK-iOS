//
//  ADMTradPlusUtils.m
//  TradPlusMediationAdMaster
//

#import "ADMTradPlusUtils.h"
#import <objc/runtime.h>
#import <math.h>

@interface TPBidInfo ()
@property (nonatomic, copy, readwrite) NSString *price;
@property (nonatomic, assign, readwrite) double priceValue;
@property (nonatomic, copy, readwrite) NSString *currency;
@property (nonatomic, assign, readwrite) TPBiddingCurrencyType currencyType;
@property (nonatomic, copy, readwrite, nullable) NSString *placementID;
@property (nonatomic, copy, readwrite, nullable) NSString *unitGroupUnitID;
@property (nonatomic, copy, readwrite, nullable) NSString *adapterClassString;
@property (nonatomic, assign, readwrite) NSTimeInterval expirationInterval;
@property (nonatomic, strong, readwrite, nullable) id winNotice;
@property (nonatomic, strong, readwrite, nullable) id biddingNotice;
@property (nonatomic, strong, readwrite, nullable) id customObject;
@property (nonatomic, copy, readwrite, nullable) NSString *errorMessage;
@end

@implementation TPBidInfo

+ (instancetype)bidInfoWithPrice:(NSString *)price
                        currency:(NSString *)currency
                       winNotice:(id)winNotice
                    customObject:(id)customObject {
    TPBidInfo *info = [[TPBidInfo alloc] init];
    info.price = [price copy] ?: @"0";
    info.priceValue = [info.price doubleValue];
    info.currency = [currency copy] ?: @"USD";
    info.currencyType = [info.currency.uppercaseString isEqualToString:@"CNY"] ? TPBiddingCurrencyTypeCNY : TPBiddingCurrencyTypeUSD;
    info.winNotice = winNotice;
    info.biddingNotice = winNotice;
    info.customObject = customObject;
    return info;
}

+ (instancetype)bidInfoC2SWithPlacementID:(NSString *)placementID
                          unitGroupUnitID:(NSString *)unitGroupUnitID
                       adapterClassString:(NSString *)adapterClassString
                                    price:(NSString *)price
                             currencyType:(TPBiddingCurrencyType)currencyType
                       expirationInterval:(NSTimeInterval)expirationInterval
                             customObject:(id)customObject
                            biddingNotice:(id)biddingNotice {
    TPBidInfo *info = [[TPBidInfo alloc] init];
    info.placementID = [placementID copy];
    info.unitGroupUnitID = [unitGroupUnitID copy];
    info.adapterClassString = [adapterClassString copy];
    info.price = [price copy] ?: @"0";
    info.priceValue = [info.price doubleValue];
    info.currencyType = currencyType;
    info.currency = (currencyType == TPBiddingCurrencyTypeCNY) ? @"CNY" : @"USD";
    info.expirationInterval = expirationInterval;
    info.customObject = customObject;
    info.biddingNotice = biddingNotice;
    info.winNotice = biddingNotice;
    return info;
}

+ (instancetype)bidInfoC2SWithErrorMessage:(NSString *)errorMessage {
    TPBidInfo *info = [[TPBidInfo alloc] init];
    info.price = @"0";
    info.priceValue = 0.0;
    info.currency = @"USD";
    info.errorMessage = [errorMessage copy] ?: @"C2S Bidding failed";
    return info;
}

- (BOOL)isValid {
    return self.errorMessage.length == 0 && isfinite(self.priceValue) && self.priceValue > 0.0;
}

@end

#if ADM_TRADPLUS_HAS_SDK

static const void *kADMTPUnitIDKey             = &kADMTPUnitIDKey;
static const void *kADMTPPlacementIDKey        = &kADMTPPlacementIDKey;
static const void *kADMTPCustomAdObjKey        = &kADMTPCustomAdObjKey;
static const void *kADMTPLastLoadErrorKey      = &kADMTPLastLoadErrorKey;
static const void *kADMTPLastShowErrorKey      = &kADMTPLastShowErrorKey;
static const void *kADMTPC2SBiddingEcpmKey     = &kADMTPC2SBiddingEcpmKey;
static const void *kADMTPC2SBiddingErrorStrKey = &kADMTPC2SBiddingErrorStrKey;

@implementation TradPlusAdWaterfallItem (ADMTradPlusCompat)

- (NSString *)unitID {
    NSString *val = objc_getAssociatedObject(self, kADMTPUnitIDKey);
    if (val.length > 0) {
        return val;
    }
    return nil;
}

- (void)setUnitID:(NSString *)unitID {
    objc_setAssociatedObject(self, kADMTPUnitIDKey, unitID, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end

@implementation TradPlusBaseAdapter (ADMTradPlusCompat)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method origLoadFail = class_getInstanceMethod(self, @selector(AdLoadFailWithError:));
        Method swizLoadFail = class_getInstanceMethod(self, @selector(adm_tp_AdLoadFailWithError:));
        if (origLoadFail && swizLoadFail) {
            method_exchangeImplementations(origLoadFail, swizLoadFail);
        }
        Method origShowFail = class_getInstanceMethod(self, @selector(AdShowFailWithError:));
        Method swizShowFail = class_getInstanceMethod(self, @selector(adm_tp_AdShowFailWithError:));
        if (origShowFail && swizShowFail) {
            method_exchangeImplementations(origShowFail, swizShowFail);
        }
    });
}

- (void)adm_tp_AdLoadFailWithError:(NSError *)error {
    self.lastLoadError = error;
    [self adm_tp_AdLoadFailWithError:error];
}

- (void)adm_tp_AdShowFailWithError:(NSError *)error {
    self.lastShowError = error;
    [self adm_tp_AdShowFailWithError:error];
}

- (id)customAdObj {
    return objc_getAssociatedObject(self, kADMTPCustomAdObjKey);
}

- (void)setCustomAdObj:(id)customAdObj {
    objc_setAssociatedObject(self, kADMTPCustomAdObjKey, customAdObj, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSError *)lastLoadError {
    return objc_getAssociatedObject(self, kADMTPLastLoadErrorKey);
}

- (void)setLastLoadError:(NSError *)lastLoadError {
    objc_setAssociatedObject(self, kADMTPLastLoadErrorKey, lastLoadError, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSError *)lastShowError {
    return objc_getAssociatedObject(self, kADMTPLastShowErrorKey);
}

- (void)setLastShowError:(NSError *)lastShowError {
    objc_setAssociatedObject(self, kADMTPLastShowErrorKey, lastShowError, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)c2sBiddingEcpm {
    return objc_getAssociatedObject(self, kADMTPC2SBiddingEcpmKey);
}

- (void)setC2sBiddingEcpm:(NSString *)c2sBiddingEcpm {
    objc_setAssociatedObject(self, kADMTPC2SBiddingEcpmKey, c2sBiddingEcpm, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)c2sBiddingErrorStr {
    return objc_getAssociatedObject(self, kADMTPC2SBiddingErrorStrKey);
}

- (void)setC2sBiddingErrorStr:(NSString *)c2sBiddingErrorStr {
    objc_setAssociatedObject(self, kADMTPC2SBiddingErrorStrKey, c2sBiddingErrorStr, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)AdLoaded {
    self.isAdReady = YES;
    self.lastLoadError = nil;
    if ([self respondsToSelector:@selector(AdLoadFinsh)]) {
        [self AdLoadFinsh];
    }
}

- (void)AdVideoStart {
    if ([self respondsToSelector:@selector(ADShowExtraCallbackWithEvent:info:)]) {
        [self ADShowExtraCallbackWithEvent:@"tradplus_play_begin" info:nil];
    }
}

- (void)AdVideoEnd {
    if ([self respondsToSelector:@selector(ADShowExtraCallbackWithEvent:info:)]) {
        [self ADShowExtraCallbackWithEvent:@"tradplus_play_end" info:nil];
    }
}

- (void)finishC2SBiddingWithEcpm:(NSString *)ecpmStr {
    NSString *safeEcpm = (ecpmStr.length > 0) ? ecpmStr : @"0";
    self.c2sBiddingEcpm = safeEcpm;
    self.c2sBiddingErrorStr = nil;
    if ([self respondsToSelector:@selector(ADLoadExtraCallbackWithEvent:info:)]) {
        [self ADLoadExtraCallbackWithEvent:@"C2SBiddingFinish"
                                      info:@{
                                          @"ecpm": safeEcpm,
                                          @"version": ADMTradPlusAdapterVersion
                                      }];
    }
}

- (void)failC2SBiddingWithErrorStr:(NSString *)errorStr {
    NSString *safeError = (errorStr.length > 0) ? errorStr : @"C2S Bidding failed";
    self.c2sBiddingErrorStr = safeError;
    self.c2sBiddingEcpm = nil;
    if ([self respondsToSelector:@selector(ADLoadExtraCallbackWithEvent:info:)]) {
        [self ADLoadExtraCallbackWithEvent:@"C2SBiddingFail"
                                      info:@{
                                          @"error": safeError
                                      }];
    }
}

- (void)getC2SBiddingWithWaterfallItem:(TradPlusAdWaterfallItem *)item {
    self.waterfallItem = item;
}

- (void)biddingSuccessWithSecondInfo:(NSDictionary *)info {
}

- (void)biddingFailWithWinInfo:(NSDictionary *)info {
}

@end

#else

@implementation TradPlusAdWaterfallItem

- (instancetype)init {
    self = [super init];
    if (self) {
        _config = [NSMutableDictionary dictionary];
        _extraInfoDictionary = [NSMutableDictionary dictionary];
    }
    return self;
}

@end

@implementation TradPlusBaseAdapter

- (void)loadAdWithWaterfallItem:(TradPlusAdWaterfallItem *)item {
    self.waterfallItem = item;
}

- (void)showAdFromRootViewController:(UIViewController *)rootViewController {
    self.rootViewController = rootViewController;
}

- (void)showAdInWindow:(UIWindow *)window bottomView:(UIView *)bottomView {
}

- (BOOL)isReady {
    return self.isAdReady;
}

- (id)getCustomObject {
    return self.customAdObj;
}

- (void)getC2SBiddingWithWaterfallItem:(TradPlusAdWaterfallItem *)item {
    self.waterfallItem = item;
}

- (void)finishC2SBiddingWithEcpm:(NSString *)ecpmStr {
    self.c2sBiddingEcpm = ecpmStr;
    self.c2sBiddingErrorStr = nil;
}

- (void)failC2SBiddingWithErrorStr:(NSString *)errorStr {
    self.c2sBiddingErrorStr = errorStr;
    self.c2sBiddingEcpm = nil;
}

- (void)biddingSuccessWithSecondInfo:(NSDictionary *)info {
}

- (void)biddingFailWithWinInfo:(NSDictionary *)info {
}

- (BOOL)extraActWithEvent:(NSString *)event info:(NSDictionary *)info {
    return [ADMTradPlusUtils handleAdapterExtraEvent:event info:info forAdapter:self];
}

- (void)ADLoadExtraCallbackWithEvent:(NSString *)event info:(NSDictionary *)info {
}

- (void)ADShowExtraCallbackWithEvent:(NSString *)event info:(NSDictionary *)info {
}

- (void)AdLoadFinsh {
    self.isAdReady = YES;
}

- (void)AdLoaded {
    self.isAdReady = YES;
    self.lastLoadError = nil;
    [self AdLoadFinsh];
}

- (void)AdLoadFailWithError:(NSError *)error {
    self.isAdReady = NO;
    self.lastLoadError = error;
}

- (void)AdShow {
}

- (void)AdShowFailWithError:(NSError *)error {
    self.lastShowError = error;
}

- (void)AdClick {
}

- (void)AdDismissed {
}

- (void)AdClose {
    [self AdDismissed];
}

- (void)AdRewardedWithInfo:(NSDictionary *)info {
}

- (void)AdVideoStart {
    [self startPlayVideo];
}

- (void)AdVideoEnd {
    [self didFinishVideo];
}

- (void)startPlayVideo {
}

- (void)didFinishVideo {
}

- (void)bannerDidAddSubView:(UIView *)subView {
}

- (void)setBannerCenterWithBanner:(UIView *)banner subView:(UIView *)subView {
    if (banner && subView) {
        banner.center = CGPointMake(CGRectGetMidX(subView.bounds), CGRectGetMidY(subView.bounds));
    }
}

- (UIView *)endRender:(NSDictionary *)viewInfo clickView:(NSArray *)array {
    return nil;
}

- (void)templateRender:(UIView *)subView {
}

@end

#endif

@implementation ADMTradPlusUtils

+ (void)dispatchOnMainThread:(dispatch_block_t)block {
    if (!block) {
        return;
    }
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

+ (UIWindow *)activeKeyWindow {
    UIApplication *app = [UIApplication sharedApplication];
    if (!app) {
        return nil;
    }
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in app.connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive &&
                [scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                for (UIWindow *window in windowScene.windows) {
                    if (window.isKeyWindow) {
                        return window;
                    }
                }
                if (windowScene.windows.count > 0) {
                    return windowScene.windows.firstObject;
                }
            }
        }
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (app.keyWindow) {
        return app.keyWindow;
    }
    return app.windows.firstObject;
#pragma clang diagnostic pop
}

+ (UIViewController *)topMostViewControllerFrom:(UIViewController *)candidate {
    UIViewController *root = candidate;
    if (!root) {
        root = [self activeKeyWindow].rootViewController;
    }
    while (root.presentedViewController && !root.presentedViewController.isBeingDismissed) {
        root = root.presentedViewController;
    }
    if ([root isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *)root;
        return nav.visibleViewController ?: nav;
    }
    if ([root isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tab = (UITabBarController *)root;
        return tab.selectedViewController ?: tab;
    }
    return root;
}

+ (NSDictionary *)serverExtraFromWaterfallItem:(TradPlusAdWaterfallItem *)item {
    if (!item) {
        return @{};
    }
    NSMutableDictionary *merged = [NSMutableDictionary dictionary];
    if ([item.config isKindOfClass:[NSDictionary class]]) {
        [merged addEntriesFromDictionary:item.config];
    }
    BOOL hasConfigPlacement = (merged[ADMTradPlusParamPlacementID] != nil ||
                               merged[ADMTradPlusParamAdUnitID] != nil ||
                               merged[ADMTradPlusParamSlotID] != nil ||
                               merged[@"placementId"] != nil ||
                               merged[@"adUnitId"] != nil ||
                               merged[@"slotId"] != nil);
    if (!hasConfigPlacement) {
        if (item.placementID.length > 0) {
            merged[ADMTradPlusParamPlacementID] = item.placementID;
        } else if ([item respondsToSelector:@selector(adsource_placement_id)] && item.adsource_placement_id.length > 0) {
            merged[ADMTradPlusParamPlacementID] = item.adsource_placement_id;
        }
    }
    if (item.unitID.length > 0 && !merged[ADMTradPlusParamAdUnitID]) {
        merged[ADMTradPlusParamAdUnitID] = item.unitID;
    }
    if ([item respondsToSelector:@selector(bannerSize)]) {
        CGSize bs = item.bannerSize;
        if (bs.width > 0 && bs.height > 0) {
            if (!merged[ADMTradPlusParamAdWidth]) {
                merged[ADMTradPlusParamAdWidth] = @(bs.width);
            }
            if (!merged[ADMTradPlusParamAdHeight]) {
                merged[ADMTradPlusParamAdHeight] = @(bs.height);
            }
        }
    }
    if ([item respondsToSelector:@selector(templateRenderSize)]) {
        CGSize ts = item.templateRenderSize;
        if (ts.width > 0 && ts.height > 0) {
            if (!merged[ADMTradPlusParamAdWidth]) {
                merged[ADMTradPlusParamAdWidth] = @(ts.width);
            }
            if (!merged[ADMTradPlusParamAdHeight]) {
                merged[ADMTradPlusParamAdHeight] = @(ts.height);
            }
        }
    }
    return [merged copy];
}

+ (NSDictionary *)localExtraFromWaterfallItem:(TradPlusAdWaterfallItem *)item {
    if (!item) {
        return @{};
    }
    NSMutableDictionary *merged = [NSMutableDictionary dictionary];
    if ([item respondsToSelector:@selector(dicCustomValue)] && [item.dicCustomValue isKindOfClass:[NSDictionary class]]) {
        [merged addEntriesFromDictionary:item.dicCustomValue];
    }
    if ([item.extraInfoDictionary isKindOfClass:[NSDictionary class]]) {
        [merged addEntriesFromDictionary:item.extraInfoDictionary];
    }
    return [merged copy];
}

#pragma mark - Custom Ext JSON Parser

+ (NSDictionary *)customExtDictionaryFromExtra:(NSDictionary *)extra {
    if (![extra isKindOfClass:[NSDictionary class]]) {
        return @{};
    }
    id rawExt = extra[ADMTradPlusParamCustomExt] ?: extra[@"customParams"] ?: extra[@"tp_params"];
    if ([rawExt isKindOfClass:[NSDictionary class]]) {
        return (NSDictionary *)rawExt;
    }
    if ([rawExt isKindOfClass:[NSString class]]) {
        NSString *extStr = [(NSString *)rawExt stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (extStr.length == 0) {
            return @{};
        }
        NSData *jsonData = [extStr dataUsingEncoding:NSUTF8StringEncoding];
        if (jsonData) {
            NSError *err = nil;
            id parsed = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&err];
            if (!err && [parsed isKindOfClass:[NSDictionary class]]) {
                return (NSDictionary *)parsed;
            }
        }
        // Fallback: unescape unicode sequences such as \u0022 -> "
        NSString *unescaped = [extStr stringByReplacingOccurrencesOfString:@"\\u0022" withString:@"\""];
        unescaped = [unescaped stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];
        NSData *fallbackData = [unescaped dataUsingEncoding:NSUTF8StringEncoding];
        if (fallbackData) {
            id parsed = [NSJSONSerialization JSONObjectWithData:fallbackData options:0 error:nil];
            if ([parsed isKindOfClass:[NSDictionary class]]) {
                return (NSDictionary *)parsed;
            }
        }
    }
    return @{};
}

+ (nullable id)valueForKeys:(NSArray<NSString *> *)keys
                serverExtra:(nullable NSDictionary *)serverExtra
                 localExtra:(nullable NSDictionary *)localExtra {
    NSDictionary *serverCustomExt = [self customExtDictionaryFromExtra:serverExtra];
    NSDictionary *localCustomExt = [self customExtDictionaryFromExtra:localExtra];
    NSDictionary *localParams = nil;
    if ([localExtra[@"localParams"] isKindOfClass:[NSDictionary class]]) {
        localParams = localExtra[@"localParams"];
    } else if ([localExtra[@"customMap"] isKindOfClass:[NSDictionary class]]) {
        localParams = localExtra[@"customMap"];
    }

    NSArray<NSDictionary *> *sources = @[
        serverExtra ?: @{},
        serverCustomExt ?: @{},
        localExtra ?: @{},
        localParams ?: @{},
        localCustomExt ?: @{}
    ];

    for (NSDictionary *dict in sources) {
        if (![dict isKindOfClass:[NSDictionary class]] || dict.count == 0) {
            continue;
        }
        for (NSString *key in keys) {
            id val = dict[key];
            if (val && val != [NSNull null]) {
                if ([val isKindOfClass:[NSString class]]) {
                    NSString *trimmed = [(NSString *)val stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    if (trimmed.length > 0) {
                        return trimmed;
                    }
                } else {
                    return val;
                }
            }
        }
    }
    return nil;
}

+ (nullable NSString *)stringFromValue:(nullable id)val {
    if (!val || val == [NSNull null]) {
        return nil;
    }
    if ([val isKindOfClass:[NSString class]]) {
        NSString *trimmed = [(NSString *)val stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        return trimmed.length > 0 ? trimmed : nil;
    }
    if ([val isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)val stringValue];
    }
    return nil;
}

+ (nullable NSString *)appIDFromServerExtra:(NSDictionary *)serverExtra
                                 localExtra:(NSDictionary *)localExtra {
    id val = [self valueForKeys:@[
        ADMTradPlusParamAppID,
        ADMTradPlusParamAppSID,
        @"appId",
        @"appSid",
        @"appid"
    ] serverExtra:serverExtra localExtra:localExtra];
    return [self stringFromValue:val];
}

+ (nullable NSString *)placementIDFromServerExtra:(NSDictionary *)serverExtra
                                       localExtra:(NSDictionary *)localExtra {
    id val = [self valueForKeys:@[
        ADMTradPlusParamPlacementID,
        ADMTradPlusParamAdUnitID,
        ADMTradPlusParamSlotID,
        @"adsource_placement_id",
        @"placementId",
        @"adUnitId",
        @"slotId",
        @"apid",
        @"unit_id"
    ] serverExtra:serverExtra localExtra:localExtra];
    return [self stringFromValue:val];
}

+ (int)bidFloorFromServerExtra:(NSDictionary *)serverExtra
                    localExtra:(NSDictionary *)localExtra {
    id val = [self valueForKeys:@[
        ADMTradPlusParamBidFloor,
        @"bidFloor",
        @"bidfloor",
        @"ecpm_floor"
    ] serverExtra:serverExtra localExtra:localExtra];
    if ([val respondsToSelector:@selector(doubleValue)]) {
        double floorVal = [val doubleValue];
        if (isfinite(floorVal) && floorVal > 0.0) {
            return (int)llround(floorVal);
        }
    }
    return 0;
}

+ (CGSize)adSizeFromServerExtra:(NSDictionary *)serverExtra
                     localExtra:(NSDictionary *)localExtra
                    defaultSize:(CGSize)defaultSize {
    id widthVal = [self valueForKeys:@[
        ADMTradPlusParamAdWidth,
        ADMTradPlusParamWidth,
        @"adWidth",
        @"banner_width"
    ] serverExtra:serverExtra localExtra:localExtra];

    id heightVal = [self valueForKeys:@[
        ADMTradPlusParamAdHeight,
        ADMTradPlusParamHeight,
        @"adHeight",
        @"banner_height"
    ] serverExtra:serverExtra localExtra:localExtra];

    CGFloat w = [widthVal respondsToSelector:@selector(doubleValue)] ? (CGFloat)[widthVal doubleValue] : 0.0;
    CGFloat h = [heightVal respondsToSelector:@selector(doubleValue)] ? (CGFloat)[heightVal doubleValue] : 0.0;

    if (w <= 0.0) {
        w = defaultSize.width;
    }
    if (h <= 0.0) {
        h = defaultSize.height;
    }
    return CGSizeMake(w, h);
}

+ (nullable NSString *)userIDFromServerExtra:(NSDictionary *)serverExtra
                                  localExtra:(NSDictionary *)localExtra {
    id val = [self valueForKeys:@[
        ADMTradPlusParamUserID,
        @"userId",
        @"custom_user_id"
    ] serverExtra:serverExtra localExtra:localExtra];
    return [self stringFromValue:val];
}

+ (nullable NSString *)customDataFromServerExtra:(NSDictionary *)serverExtra
                                      localExtra:(NSDictionary *)localExtra {
    id val = [self valueForKeys:@[
        ADMTradPlusParamCustomData,
        ADMTradPlusParamExtraInfo,
        @"customData",
        @"extraInfo"
    ] serverExtra:serverExtra localExtra:localExtra];
    return [self stringFromValue:val];
}

+ (void)updateAdMasterRuntimeFromServerExtra:(NSDictionary *)serverExtra
                                  localExtra:(NSDictionary *)localExtra {
    ADMSetting *setting = [ADMSetting sharedInstance];
    id testVal = [self valueForKeys:@[ADMTradPlusParamTest, ADMTradPlusParamTestMode, @"isTest", @"is_test"]
                        serverExtra:serverExtra
                         localExtra:localExtra];
    if ([testVal respondsToSelector:@selector(boolValue)]) {
        setting.isTest = [testVal boolValue];
    }

    id mockVal = [self valueForKeys:@[ADMTradPlusParamMock, ADMTradPlusParamMockMode, @"isMock", @"is_mock"]
                        serverExtra:serverExtra
                         localExtra:localExtra];
    if ([mockVal respondsToSelector:@selector(boolValue)]) {
        setting.isMock = [mockVal boolValue];
    }
}

+ (ADMRequest *)requestFromServerExtra:(NSDictionary *)serverExtra
                            localExtra:(NSDictionary *)localExtra {
    ADMRequest *request = [ADMRequest defaultRequest];
    request.bidFloor = (int)[self bidFloorFromServerExtra:serverExtra localExtra:localExtra];
    return request;
}

+ (double)parseECPMCentsFromString:(NSString *)ecpmString {
    if (![ecpmString isKindOfClass:[NSString class]]) {
        if ([ecpmString respondsToSelector:@selector(doubleValue)]) {
            double v = [(id)ecpmString doubleValue];
            return (isfinite(v) && v > 0.0) ? v : 0.0;
        }
        return 0.0;
    }
    NSString *trimmed = [ecpmString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) {
        return 0.0;
    }
    double val = [trimmed doubleValue];
    if (!isfinite(val) || val <= 0.0) {
        return 0.0;
    }
    return val;
}

+ (NSString *)formatECPMStringFromCents:(double)ecpmCents {
    if (!isfinite(ecpmCents) || ecpmCents <= 0.0) {
        return @"0";
    }
    double rounded = round(ecpmCents);
    if (fabs(ecpmCents - rounded) < 1e-6) {
        return [NSString stringWithFormat:@"%.0f", rounded];
    }
    return [NSString stringWithFormat:@"%.2f", ecpmCents];
}

+ (NSString *)parseECPMYuanStringFromCents:(double)ecpmCents {
    if (!isfinite(ecpmCents) || ecpmCents <= 0.0) {
        return @"0";
    }
    return [NSString stringWithFormat:@"%.2f", ecpmCents / 100.0];
}

+ (NSError *)errorWithCode:(ADMTradPlusErrorCode)code
               description:(NSString *)description {
    NSString *desc = (description.length > 0) ? description : @"TradPlus AdMaster Adapter error";
    return [NSError errorWithDomain:ADMTradPlusErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: desc}];
}

+ (ADMTradPlusErrorCode)classifyADMErrorCode:(NSInteger)admCode
                                 defaultCode:(ADMTradPlusErrorCode)defaultCode {
    if (admCode == 204 || admCode == 1001 || admCode == 2001 || admCode == 3001 || admCode == 3010001) {
        return ADMTradPlusErrorCodeNoFill;
    }
    if (admCode == 400 || admCode == 4001 || admCode == 1010001 || admCode == -4001) {
        return ADMTradPlusErrorCodeInvalidParameters;
    }
    if (admCode == 3040001) {
        return ADMTradPlusErrorCodeAdPresentFailed;
    }
    return defaultCode;
}

+ (NSError *)errorFromADMError:(NSError *)admError
                   defaultCode:(ADMTradPlusErrorCode)defaultCode
            defaultDescription:(NSString *)defaultDescription {
    if (!admError) {
        return [self errorWithCode:defaultCode description:defaultDescription];
    }
    ADMTradPlusErrorCode mappedCode = [self classifyADMErrorCode:admError.code defaultCode:defaultCode];
    NSString *msg = admError.localizedDescription.length > 0 ? admError.localizedDescription : defaultDescription;
    return [NSError errorWithDomain:ADMTradPlusErrorDomain
                               code:mappedCode
                           userInfo:@{
                               NSLocalizedDescriptionKey: msg ?: @"AdMaster error",
                               NSUnderlyingErrorKey: admError
                           }];
}

+ (BOOL)handleAdapterExtraEvent:(NSString *)event
                           info:(NSDictionary *)info
                     forAdapter:(TradPlusBaseAdapter *)adapter {
    if (![event isKindOfClass:[NSString class]] || !adapter) {
        return NO;
    }
    if ([event isEqualToString:@"C2SBidding"]) {
        [adapter getC2SBiddingWithWaterfallItem:adapter.waterfallItem];
        return YES;
    }
    if ([event isEqualToString:@"LoadAdC2SBidding"]) {
        [adapter loadAdWithWaterfallItem:adapter.waterfallItem];
        return YES;
    }
    if ([event isEqualToString:@"C2SLoss"]) {
        [adapter biddingFailWithWinInfo:info];
        return YES;
    }
    if ([event isEqualToString:@"C2SWin"]) {
        [adapter biddingSuccessWithSecondInfo:info];
        return YES;
    }
    return NO;
}

@end
