//
//  ADMCustomEventRewarded.h
//  GADMediationAdMaster
//
//  Created by AdMasterDev on 2025/8/25.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface ADMCustomEventRewarded : NSObject

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:(GADMediationRewardedLoadCompletionHandler)completionHandler;

@end
