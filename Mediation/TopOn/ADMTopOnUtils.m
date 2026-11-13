#import "ADMTopOnUtils.h"

#if __has_include(<AdMasterSDK/AdMasterSDK.h>)
#import <AdMasterSDK/AdMasterSDK.h>
#else
#import "ADMRequest.h"
#import "ADMError.h"
#import "ADMManager.h"
@interface ADMSetting : NSObject
@property (nonatomic, assign) BOOL isTest;
@property (nonatomic, assign) BOOL isMock;
+ (ADMSetting *)sharedInstance;
@end
#endif

#if !ADM_TOPON_HAS_ANYTHINK_SDK

@implementation ATBidWinLossResult
@end

@interface ATBidInfo ()
@property (nonatomic, copy, readwrite) NSString *placementID;
@property (nonatomic, copy, readwrite) NSString *unitID;
@property (nonatomic, copy, readwrite) NSString *adapterClassString;
@property (nonatomic, copy, readwrite) NSString *price;
@property (nonatomic, assign, readwrite) ATBiddingCurrencyType currencyType;
@property (nonatomic, assign, readwrite, getter=isValid) BOOL valid;
@property (nonatomic, assign, readwrite) NSTimeInterval expirationInterval;
@property (nonatomic, strong, readwrite, nullable) id customObject;
@end

@implementation ATBidInfo

+ (instancetype)bidInfoC2SWithPlacementID:(NSString *)placementID
                          unitGroupUnitID:(NSString *)unitGroupUnitID
                       adapterClassString:(NSString *)adapterClassString
                                    price:(NSString *)price
                             currencyType:(ATBiddingCurrencyType)currencyType
                       expirationInterval:(NSTimeInterval)expirationInterval
                             customObject:(nullable id)customObject {
    ATBidInfo *info = [[ATBidInfo alloc] init];
    info.placementID = placementID ?: @"";
    info.unitID = unitGroupUnitID ?: @"";
    info.adapterClassString = adapterClassString ?: @"";
    info.price = price ?: @"0";
    info.currencyType = currencyType;
    info.expirationInterval = expirationInterval;
    info.customObject = customObject;
    info.valid = YES;
    return info;
}

@end

#endif

#pragma mark - Internal Helpers

static BOOL ADMTopOnIsHexChar(unichar c) {
    return (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F');
}

static unichar ADMTopOnHexValue(unichar c) {
    if (c >= '0' && c <= '9') {
        return (unichar)(c - '0');
    }
    if (c >= 'a' && c <= 'f') {
        return (unichar)(10 + (c - 'a'));
    }
    if (c >= 'A' && c <= 'F') {
        return (unichar)(10 + (c - 'A'));
    }
    return 0;
}

static NSString *ADMTopOnUnescapeUnicodeLiterals(NSString *input) {
    if (![input isKindOfClass:[NSString class]] || input.length < 6) {
        return input;
    }
    if ([input rangeOfString:@"\\u" options:NSCaseInsensitiveSearch].location == NSNotFound) {
        return input;
    }
    NSUInteger length = input.length;
    NSMutableString *result = [NSMutableString stringWithCapacity:length];
    NSUInteger i = 0;
    while (i < length) {
        unichar ch = [input characterAtIndex:i];
        if (ch == '\\' && i + 5 < length) {
            unichar uChar = [input characterAtIndex:i + 1];
            if (uChar == 'u' || uChar == 'U') {
                unichar h0 = [input characterAtIndex:i + 2];
                unichar h1 = [input characterAtIndex:i + 3];
                unichar h2 = [input characterAtIndex:i + 4];
                unichar h3 = [input characterAtIndex:i + 5];
                if (ADMTopOnIsHexChar(h0) && ADMTopOnIsHexChar(h1) &&
                    ADMTopOnIsHexChar(h2) && ADMTopOnIsHexChar(h3)) {
                    uint16_t highByte = (uint16_t)((ADMTopOnHexValue(h0) << 12) | (ADMTopOnHexValue(h1) << 8));
                    uint16_t lowByte = (uint16_t)((ADMTopOnHexValue(h2) << 4) | ADMTopOnHexValue(h3));
                    unichar decoded = (unichar)(highByte | lowByte);
                    [result appendFormat:@"%C", decoded];
                    i += 6;
                    continue;
                }
            }
        }
        [result appendFormat:@"%C", ch];
        i++;
    }
    return result;
}

static BOOL ADMTopOnIsValueEmpty(id _Nullable value) {
    if (value == nil || value == [NSNull null]) {
        return YES;
    }
    if ([value isKindOfClass:[NSString class]]) {
        NSString *trimmed = [(NSString *)value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        return trimmed.length == 0;
    }
    return NO;
}

static NSString *_Nullable ADMTopOnTrimmedStringFromValue(id _Nullable value) {
    if (value == nil || value == [NSNull null]) {
        return nil;
    }
    if ([value isKindOfClass:[NSString class]]) {
        NSString *trimmed = [(NSString *)value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        return trimmed.length > 0 ? trimmed : nil;
    }
    if ([value isKindOfClass:[NSNumber class]]) {
        NSString *str = [(NSNumber *)value stringValue];
        return str.length > 0 ? str : nil;
    }
    return nil;
}

static NSDictionary<NSString *, id> *_Nullable ADMTopOnParseCustomExtObject(id _Nullable rawCustomExt) {
    if (rawCustomExt == nil || rawCustomExt == [NSNull null]) {
        return nil;
    }
    NSDictionary *parsedDict = nil;
    if ([rawCustomExt isKindOfClass:[NSDictionary class]]) {
        parsedDict = (NSDictionary *)rawCustomExt;
    } else if ([rawCustomExt isKindOfClass:[NSString class]]) {
        NSString *rawString = [(NSString *)rawCustomExt stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (rawString.length == 0) {
            return nil;
        }
        NSData *directData = [rawString dataUsingEncoding:NSUTF8StringEncoding];
        if (directData) {
            id obj = [NSJSONSerialization JSONObjectWithData:directData options:0 error:nil];
            if ([obj isKindOfClass:[NSDictionary class]]) {
                parsedDict = (NSDictionary *)obj;
            }
        }
        if (!parsedDict) {
            NSString *unescaped = ADMTopOnUnescapeUnicodeLiterals(rawString);
            NSData *unescapedData = [unescaped dataUsingEncoding:NSUTF8StringEncoding];
            if (unescapedData) {
                id obj = [NSJSONSerialization JSONObjectWithData:unescapedData options:0 error:nil];
                if ([obj isKindOfClass:[NSDictionary class]]) {
                    parsedDict = (NSDictionary *)obj;
                }
            }
        }
    }
    if (!parsedDict) {
        return nil;
    }
    NSMutableDictionary<NSString *, id> *cleaned = [NSMutableDictionary dictionaryWithCapacity:parsedDict.count];
    for (id key in parsedDict) {
        if (![key isKindOfClass:[NSString class]]) {
            continue;
        }
        id val = parsedDict[key];
        if (val == nil || val == [NSNull null]) {
            continue;
        }
        if ([val isKindOfClass:[NSString class]]) {
            val = ADMTopOnUnescapeUnicodeLiterals((NSString *)val);
        }
        cleaned[(NSString *)key] = val;
    }
    return cleaned;
}

static BOOL ADMTopOnBoolFromValue(id _Nullable value) {
    if ([value isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)value boolValue];
    }
    if ([value isKindOfClass:[NSString class]]) {
        NSString *trimmed = [[(NSString *)value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
        return [trimmed isEqualToString:@"1"] ||
               [trimmed isEqualToString:@"true"] ||
               [trimmed isEqualToString:@"yes"];
    }
    return NO;
}

static CGFloat ADMTopOnFloatFromValue(id _Nullable value) {
    if ([value isKindOfClass:[NSNumber class]]) {
        double v = [(NSNumber *)value doubleValue];
        return (isfinite(v) && v > 0.0) ? (CGFloat)v : 0.0;
    }
    if ([value isKindOfClass:[NSString class]]) {
        NSString *trimmed = [(NSString *)value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimmed.length > 0) {
            double v = [trimmed doubleValue];
            return (isfinite(v) && v > 0.0) ? (CGFloat)v : 0.0;
        }
    }
    return 0.0;
}

#pragma mark - ADMTopOnUtils Implementation

@implementation ADMTopOnUtils

+ (NSDictionary<NSString *, id> *)mergedParametersWithServerExtra:(nullable NSDictionary *)serverExtra
                                                       localExtra:(nullable NSDictionary *)localExtra {
    NSMutableDictionary<NSString *, id> *merged = [NSMutableDictionary dictionary];

    // 1. Apply localExtra first
    if ([localExtra isKindOfClass:[NSDictionary class]]) {
        for (id key in localExtra) {
            if (![key isKindOfClass:[NSString class]]) {
                continue;
            }
            id value = localExtra[key];
            if (!ADMTopOnIsValueEmpty(value)) {
                merged[(NSString *)key] = value;
            }
        }
    }

    // 2. Apply serverExtra (serverExtra takes precedence for non-empty values)
    if ([serverExtra isKindOfClass:[NSDictionary class]]) {
        for (id key in serverExtra) {
            if (![key isKindOfClass:[NSString class]]) {
                continue;
            }
            id value = serverExtra[key];
            if (!ADMTopOnIsValueEmpty(value)) {
                merged[(NSString *)key] = value;
            }
        }
    }

    // 3. Parse custom_ext from localExtra and serverExtra, filling keys that are missing or empty at top level
    NSDictionary<NSString *, id> *localCustomExt = [localExtra isKindOfClass:[NSDictionary class]]
        ? ADMTopOnParseCustomExtObject(localExtra[ADMTopOnParamKeyCustomExt])
        : nil;
    NSDictionary<NSString *, id> *serverCustomExt = [serverExtra isKindOfClass:[NSDictionary class]]
        ? ADMTopOnParseCustomExtObject(serverExtra[ADMTopOnParamKeyCustomExt])
        : nil;

    if (localCustomExt) {
        for (NSString *key in localCustomExt) {
            id value = localCustomExt[key];
            if (ADMTopOnIsValueEmpty(merged[key]) && !ADMTopOnIsValueEmpty(value)) {
                merged[key] = value;
            }
        }
    }
    if (serverCustomExt) {
        for (NSString *key in serverCustomExt) {
            id value = serverCustomExt[key];
            // serverExtra's custom_ext overrides localExtra's custom_ext if top-level didn't specify it
            BOOL hasTopLevel = ([serverExtra isKindOfClass:[NSDictionary class]] && !ADMTopOnIsValueEmpty(serverExtra[key])) ||
                               ([localExtra isKindOfClass:[NSDictionary class]] && !ADMTopOnIsValueEmpty(localExtra[key]));
            if (!hasTopLevel && !ADMTopOnIsValueEmpty(value)) {
                merged[key] = value;
            }
        }
    }

    return [merged copy];
}

+ (nullable NSString *)appIDFromServerExtra:(nullable NSDictionary *)serverExtra
                                 localExtra:(nullable NSDictionary *)localExtra {
    NSDictionary<NSString *, id> *merged = [self mergedParametersWithServerExtra:serverExtra localExtra:localExtra];
    return ADMTopOnTrimmedStringFromValue(merged[ADMTopOnParamKeyAppID]);
}

+ (nullable NSString *)placementIDFromServerExtra:(nullable NSDictionary *)serverExtra
                                       localExtra:(nullable NSDictionary *)localExtra {
    NSDictionary<NSString *, id> *merged = [self mergedParametersWithServerExtra:serverExtra localExtra:localExtra];
    NSString *placementID = ADMTopOnTrimmedStringFromValue(merged[ADMTopOnParamKeyPlacementID]);
    if (placementID.length > 0) {
        return placementID;
    }
    NSString *adUnitID = ADMTopOnTrimmedStringFromValue(merged[ADMTopOnParamKeyAdUnitID]);
    if (adUnitID.length > 0) {
        return adUnitID;
    }
    NSString *slotID = ADMTopOnTrimmedStringFromValue(merged[ADMTopOnParamKeySlotID]);
    if (slotID.length > 0) {
        return slotID;
    }
    return nil;
}

+ (NSString *)unitIDFromServerExtra:(nullable NSDictionary *)serverExtra
                         localExtra:(nullable NSDictionary *)localExtra {
    NSDictionary<NSString *, id> *merged = [self mergedParametersWithServerExtra:serverExtra localExtra:localExtra];
    NSString *unitID = ADMTopOnTrimmedStringFromValue(merged[ADMTopOnParamKeyUnitID]);
    if (unitID.length > 0) {
        return unitID;
    }
    NSString *placementID = [self placementIDFromServerExtra:serverExtra localExtra:localExtra];
    return placementID ?: @"";
}

+ (int)bidFloorFromServerExtra:(nullable NSDictionary *)serverExtra
                    localExtra:(nullable NSDictionary *)localExtra {
    NSDictionary<NSString *, id> *merged = [self mergedParametersWithServerExtra:serverExtra localExtra:localExtra];
    id rawBidFloor = merged[ADMTopOnParamKeyBidFloor];
    if ([rawBidFloor isKindOfClass:[NSNumber class]]) {
        double val = [(NSNumber *)rawBidFloor doubleValue];
        if (!isfinite(val) || val <= 0.0) {
            return 0;
        }
        return (val >= (double)INT_MAX) ? INT_MAX : (int)val;
    }
    if ([rawBidFloor isKindOfClass:[NSString class]]) {
        NSString *trimmed = [(NSString *)rawBidFloor stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimmed.length > 0) {
            double val = [trimmed doubleValue];
            if (!isfinite(val) || val <= 0.0) {
                return 0;
            }
            return (val >= (double)INT_MAX) ? INT_MAX : (int)val;
        }
    }
    return 0;
}

+ (BOOL)isTestModeFromServerExtra:(nullable NSDictionary *)serverExtra
                       localExtra:(nullable NSDictionary *)localExtra {
    NSDictionary<NSString *, id> *merged = [self mergedParametersWithServerExtra:serverExtra localExtra:localExtra];
    return ADMTopOnBoolFromValue(merged[ADMTopOnParamKeyTest]);
}

+ (BOOL)isMockModeFromServerExtra:(nullable NSDictionary *)serverExtra
                       localExtra:(nullable NSDictionary *)localExtra {
    NSDictionary<NSString *, id> *merged = [self mergedParametersWithServerExtra:serverExtra localExtra:localExtra];
    return ADMTopOnBoolFromValue(merged[ADMTopOnParamKeyMock]);
}

+ (CGSize)adSizeFromServerExtra:(nullable NSDictionary *)serverExtra
                     localExtra:(nullable NSDictionary *)localExtra
                    defaultSize:(CGSize)defaultSize {
    NSDictionary<NSString *, id> *merged = [self mergedParametersWithServerExtra:serverExtra localExtra:localExtra];
    CGFloat width = ADMTopOnFloatFromValue(merged[ADMTopOnParamKeyAdWidth]);
    if (width <= 0.0) {
        width = ADMTopOnFloatFromValue(merged[ADMTopOnParamKeyWidth]);
    }
    CGFloat height = ADMTopOnFloatFromValue(merged[ADMTopOnParamKeyAdHeight]);
    if (height <= 0.0) {
        height = ADMTopOnFloatFromValue(merged[ADMTopOnParamKeyHeight]);
    }
    if (width > 0.0 && height > 0.0) {
        return CGSizeMake(width, height);
    }
    id rawSize = merged[@"adSize"] ?: merged[@"size"] ?: merged[@"ad_size"];
    if ([rawSize isKindOfClass:[NSValue class]]) {
        CGSize valSize = [(NSValue *)rawSize CGSizeValue];
        if (valSize.width > 0.0 && valSize.height > 0.0) {
            return valSize;
        }
    } else if ([rawSize isKindOfClass:[NSString class]]) {
        NSArray<NSString *> *parts = [[(NSString *)rawSize lowercaseString] componentsSeparatedByString:@"x"];
        if (parts.count == 2) {
            CGFloat parsedW = ADMTopOnFloatFromValue(parts[0]);
            CGFloat parsedH = ADMTopOnFloatFromValue(parts[1]);
            if (parsedW > 0.0 && parsedH > 0.0) {
                return CGSizeMake(parsedW, parsedH);
            }
        }
    }
    return defaultSize;
}

+ (nullable NSString *)userIDFromServerExtra:(nullable NSDictionary *)serverExtra
                                  localExtra:(nullable NSDictionary *)localExtra {
    NSDictionary<NSString *, id> *merged = [self mergedParametersWithServerExtra:serverExtra localExtra:localExtra];
    return ADMTopOnTrimmedStringFromValue(merged[ADMTopOnParamKeyUserID]);
}

+ (nullable NSString *)customDataFromServerExtra:(nullable NSDictionary *)serverExtra
                                      localExtra:(nullable NSDictionary *)localExtra {
    NSDictionary<NSString *, id> *merged = [self mergedParametersWithServerExtra:serverExtra localExtra:localExtra];
    return ADMTopOnTrimmedStringFromValue(merged[ADMTopOnParamKeyCustomData]);
}

+ (void)updateAdMasterRuntimeFromServerExtra:(nullable NSDictionary *)serverExtra
                                  localExtra:(nullable NSDictionary *)localExtra {
    NSDictionary<NSString *, id> *merged = [self mergedParametersWithServerExtra:serverExtra localExtra:localExtra];
    if (merged[ADMTopOnParamKeyTest] != nil) {
        [ADMSetting sharedInstance].isTest = ADMTopOnBoolFromValue(merged[ADMTopOnParamKeyTest]);
    }
    if (merged[ADMTopOnParamKeyMock] != nil) {
        [ADMSetting sharedInstance].isMock = ADMTopOnBoolFromValue(merged[ADMTopOnParamKeyMock]);
    }
}

+ (ADMRequest *)requestFromServerExtra:(nullable NSDictionary *)serverExtra
                            localExtra:(nullable NSDictionary *)localExtra {
    ADMRequest *request = [ADMRequest defaultRequest];
    request.bidFloor = [self bidFloorFromServerExtra:serverExtra localExtra:localExtra];
    return request;
}

+ (double)parseECPMCentsFromString:(nullable NSString *)ecpmString {
    if (ecpmString == nil || (id)ecpmString == [NSNull null]) {
        return 0.0;
    }
    if ([ecpmString isKindOfClass:[NSNumber class]]) {
        double v = [(NSNumber *)ecpmString doubleValue];
        return (isfinite(v) && v >= 0.0) ? v : 0.0;
    }
    if (![ecpmString isKindOfClass:[NSString class]]) {
        return 0.0;
    }
    NSString *trimmed = [ecpmString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) {
        return 0.0;
    }
    NSScanner *scanner = [NSScanner scannerWithString:trimmed];
    double value = 0.0;
    if (![scanner scanDouble:&value] || !scanner.isAtEnd) {
        return 0.0;
    }
    return (isfinite(value) && value >= 0.0) ? value : 0.0;
}

+ (NSError *)errorWithCode:(ADMTopOnErrorCode)code description:(NSString *)description {
    NSString *safeDesc = description.length > 0 ? description : @"Unknown TopOn mediation error";
    return [NSError errorWithDomain:ADMTopOnErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: safeDesc}];
}

+ (NSError *)errorFromADMError:(nullable ADMError *)admError
                   defaultCode:(ADMTopOnErrorCode)defaultCode
            defaultDescription:(NSString *)defaultDescription {
    id errObj = admError;
    if (errObj == nil || errObj == [NSNull null]) {
        return [self errorWithCode:defaultCode description:defaultDescription];
    }
    if ([errObj isKindOfClass:[NSError class]]) {
        NSError *nsErr = (NSError *)errObj;
        NSInteger code = nsErr.code != 0 ? nsErr.code : defaultCode;
        NSString *desc = nsErr.localizedDescription.length > 0 ? nsErr.localizedDescription : (defaultDescription ?: @"Unknown error");
        return [NSError errorWithDomain:ADMTopOnErrorDomain
                                   code:code
                               userInfo:@{
                                   NSLocalizedDescriptionKey: desc,
                                   NSUnderlyingErrorKey: nsErr
                               }];
    }
    NSInteger resolvedCode = defaultCode;
    if ([errObj respondsToSelector:@selector(code)]) {
        NSInteger c = [(NSError *)errObj code];
        if (c != 0) {
            resolvedCode = c;
        }
    }
    NSString *resolvedDesc = defaultDescription;
    if ([errObj respondsToSelector:@selector(localizedDescription)]) {
        NSString *d = [(NSError *)errObj localizedDescription];
        if ([d isKindOfClass:[NSString class]] && d.length > 0) {
            resolvedDesc = d;
        }
    }
    return [self errorWithCode:(ADMTopOnErrorCode)resolvedCode description:resolvedDesc];
}

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

@end
