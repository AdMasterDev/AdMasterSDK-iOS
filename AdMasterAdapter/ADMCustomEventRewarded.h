//
//  ADMCustomEventRewarded.h
//  GADMediationAdMaster
//
//  Created by AdMasterDev on 2025/8/25.
//

#ifndef ADMCustomEventRewarded_h
#define ADMCustomEventRewarded_h

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface ADMCustomEventRewarded : NSObject

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:(GADMediationRewardedLoadCompletionHandler)completionHandler;

@end

#endif /* ADMCustomEventRewarded_h */