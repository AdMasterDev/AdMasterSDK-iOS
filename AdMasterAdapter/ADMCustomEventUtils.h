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

NS_ASSUME_NONNULL_BEGIN

@interface ADMCustomEventUtils : NSObject

+ (NSError *)errorWithCode:(NSInteger)code description:(NSString *)description;

+ (NSString *)appIDFromAdConfigurationParameter:(NSString *)parameter;

+ (NSString *)adUnitIDFromAdConfigurationParameter:(NSString *)parameter;

+ (BOOL)isTestFromAdConfigurationParameter:(NSString *)parameter;

@end

NS_ASSUME_NONNULL_END

#endif /* ADMCustomEventUtils_h */