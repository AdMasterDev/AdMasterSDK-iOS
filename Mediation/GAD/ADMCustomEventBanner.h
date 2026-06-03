//
//  ADMCustomEventBanner.h
//  GADMediationAdMaster
//
//  Created by AdMasterDev on 2025/8/25.
//

#ifndef ADMCustomEventBanner_h
#define ADMCustomEventBanner_h

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface ADMCustomEventBanner : NSObject

- (void)loadBannerForAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler;

@end

#endif /* ADMCustomEventBanner_h */