//
//  ADMCustomEventUtils.m
//  GADMediationAdMaster
//
//  Created by AdMasterDev on 2025/8/25.
//

#import "ADMCustomEventUtils.h"
#import <AdMasterSDK/AdMasterSDK.h>

@implementation ADMCustomEventUtils

+ (NSError *)errorWithCode:(NSInteger)code description:(NSString *)description {
    return [NSError errorWithDomain:ADMCustomEventErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: description}];
}

+ (NSString *)appIDFromAdConfigurationParameter:(NSString *)parameter {
    id value = [self parseParameter:parameter][ADMCustomEventAppID];
    if ([value isKindOfClass:[NSString class]]) {
        return value;
    }
    return nil;
}

+ (NSString *)adUnitIDFromAdConfigurationParameter:(NSString *)parameter {
    id value = [self parseParameter:parameter][ADMCustomEventAdUnitID];
    if ([value isKindOfClass:[NSString class]]) {
        return value;
    }
    return nil;
}

static BOOL ADMBoolFromJSONValue(id value) {
    if ([value isKindOfClass:[NSNumber class]]) {
        return [value boolValue];
    }
    if ([value isKindOfClass:[NSString class]]) {
        NSString *lower = [(NSString *)value lowercaseString];
        return [lower isEqualToString:@"true"] || [lower isEqualToString:@"yes"] || [lower isEqualToString:@"1"];
    }
    return NO;
}

+ (BOOL)isTestFromAdConfigurationParameter:(NSString *)parameter {
    return ADMBoolFromJSONValue([self parseParameter:parameter][ADMCustomEventIsTest]);
}

+ (BOOL)isMockFromAdConfigurationParameter:(nullable NSString *)parameter {
    return ADMBoolFromJSONValue([self parseParameter:parameter][ADMCustomEventIsMock]);
}

+ (int)bidFloorFromDictionary:(nullable NSDictionary *)dict {
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return 0;
    }
    id rawValue = dict[ADMCustomEventParameterKeyBidFloor];
    if ([rawValue isKindOfClass:[NSNumber class]]) {
        double val = [(NSNumber *)rawValue doubleValue];
        if (!isfinite(val) || val <= 0.0) {
            return 0;
        }
        return (val >= (double)INT_MAX) ? INT_MAX : (int)val;
    }
    if ([rawValue isKindOfClass:[NSString class]]) {
        NSString *trimmed = [(NSString *)rawValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
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

+ (int)bidFloorFromAdConfigurationParameter:(nullable NSString *)parameter {
    return [self bidFloorFromDictionary:[self parseParameter:parameter]];
}

+ (int)bidFloorFromAdConfiguration:(nullable GADMediationAdConfiguration *)adConfiguration {
    if (!adConfiguration) {
        return 0;
    }
    NSString *parameter = adConfiguration.credentials.settings[@"parameter"];
    int floor = [self bidFloorFromAdConfigurationParameter:parameter];
    if (floor > 0) {
        return floor;
    }
    return [self bidFloorFromDictionary:adConfiguration.credentials.settings];
}

+ (ADMRequest *)requestFromAdConfigurationParameter:(nullable NSString *)parameter {
    ADMRequest *request = [ADMRequest defaultRequest];
    request.bidFloor = [self bidFloorFromAdConfigurationParameter:parameter];
    return request;
}

+ (ADMRequest *)requestFromAdConfiguration:(nullable GADMediationAdConfiguration *)adConfiguration {
    ADMRequest *request = [ADMRequest defaultRequest];
    request.bidFloor = [self bidFloorFromAdConfiguration:adConfiguration];
    return request;
}

+ (void)updateAdMasterRuntimeFromAdConfigurationParameter:(nullable NSString *)parameter {
    NSDictionary *dict = [self parseParameter:parameter];
    if (dict[ADMCustomEventIsTest] != nil) {
        [ADMSetting sharedInstance].isTest = ADMBoolFromJSONValue(dict[ADMCustomEventIsTest]);
    }
    if (dict[ADMCustomEventIsMock] != nil) {
        [ADMSetting sharedInstance].isMock = ADMBoolFromJSONValue(dict[ADMCustomEventIsMock]);
    }
    NSString *appID = [self appIDFromAdConfigurationParameter:parameter];
    if (appID.length > 0) {
        [ADMManager startWithAppsid:appID completionHandler:^(BOOL success, NSError *_Nullable error) {
            (void)success;
            (void)error;
        }];
    }
}

+ (void)ensureSDKInitializedWithAdConfiguration:(nullable GADMediationAdConfiguration *)adConfiguration
                                     completion:(nullable dispatch_block_t)completion {
    NSString *parameter = adConfiguration.credentials.settings[@"parameter"];
    [self updateAdMasterRuntimeFromAdConfigurationParameter:parameter];
    NSString *appID = [self appIDFromAdConfigurationParameter:parameter];
    if (appID.length > 0) {
        [ADMManager startWithAppsid:appID completionHandler:^(BOOL success, NSError *_Nullable error) {
            (void)success;
            (void)error;
            if (completion) {
                completion();
            }
        }];
    } else if (completion) {
        completion();
    }
}

+ (NSDictionary *)parseParameter:(NSString *)parameter {
    if (parameter == nil || parameter.length == 0) {
        return @{};
    }
    
    NSError *jsonError = nil;
    NSData *jsonData = [parameter dataUsingEncoding:NSUTF8StringEncoding];
    if (!jsonData) {
        return @{};
    }
    
    id jsonObj = [NSJSONSerialization JSONObjectWithData:jsonData
                                                 options:0
                                                   error:&jsonError];
    if (jsonError) {
        return @{};
    }
    
    if (![jsonObj isKindOfClass:[NSDictionary class]]) {
        return @{};
    }
    return (NSDictionary *)jsonObj;
}

@end
