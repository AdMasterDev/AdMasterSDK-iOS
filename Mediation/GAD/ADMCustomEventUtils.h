//
//  ADMCustomEventUtils.h
//  GADMediationAdMaster
//
//  Created by AdMasterDev on 2025/8/25.
//

#ifndef ADMCustomEventUtils_h
#define ADMCustomEventUtils_h

#import <Foundation/Foundation.h>
#import "ADMCustomEventConstants.h"
#import "ADMCustomEvent.h"

@class ADMRequest;

NS_ASSUME_NONNULL_BEGIN

@interface ADMCustomEventUtils : NSObject

+ (NSError *)errorWithCode:(NSInteger)code description:(NSString *)description;

+ (nullable NSString *)appIDFromAdConfigurationParameter:(nullable NSString *)parameter;

+ (nullable NSString *)adUnitIDFromAdConfigurationParameter:(nullable NSString *)parameter;

+ (BOOL)isTestFromAdConfigurationParameter:(nullable NSString *)parameter;

+ (BOOL)isMockFromAdConfigurationParameter:(nullable NSString *)parameter;

+ (int)bidFloorFromDictionary:(nullable NSDictionary *)dict;

+ (int)bidFloorFromAdConfigurationParameter:(nullable NSString *)parameter;

+ (int)bidFloorFromAdConfiguration:(nullable GADMediationAdConfiguration *)adConfiguration;

+ (ADMRequest *)requestFromAdConfigurationParameter:(nullable NSString *)parameter;

+ (ADMRequest *)requestFromAdConfiguration:(nullable GADMediationAdConfiguration *)adConfiguration;

+ (void)updateAdMasterRuntimeFromAdConfigurationParameter:(nullable NSString *)parameter;

+ (void)ensureSDKInitializedWithAdConfiguration:(nullable GADMediationAdConfiguration *)adConfiguration
                                     completion:(nullable dispatch_block_t)completion;

@end

NS_ASSUME_NONNULL_END

#endif /* ADMCustomEventUtils_h */
