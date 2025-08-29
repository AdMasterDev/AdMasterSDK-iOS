//
//  ADMCustomEventBanner.h
//  GADMediationAdMaster
//
//  Created by AdMasterDev on 2025/8/25.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface ADMCustomEventBanner : NSObject

- (void)loadBannerForAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler;

@end
