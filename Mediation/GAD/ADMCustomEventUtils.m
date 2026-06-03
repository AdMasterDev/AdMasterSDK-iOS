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

+ (BOOL)isMockFromAdConfigurationParameter:(NSString *)parameter {
    return ADMBoolFromJSONValue([self parseParameter:parameter][ADMCustomEventIsMock]);
}

+ (void)updateAdMasterRuntimeFromAdConfigurationParameter:(NSString *)parameter {
    BOOL isTestMode = [self isTestFromAdConfigurationParameter:parameter];
    BOOL isMockMode = [self isMockFromAdConfigurationParameter:parameter];
    [ADMSetting sharedInstance].isTest = isTestMode;
    [ADMSetting sharedInstance].isMock = isMockMode;
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
