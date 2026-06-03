//
//  ADMCustomEventNativeAd.h
//  GADMediationAdMaster
//
//  Created by AdMasterDev on 2025/8/25.
//

#ifndef ADMCustomEventNativeAd_h
#define ADMCustomEventNativeAd_h

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface ADMCustomEventNativeAd : NSObject

- (void)loadNativeAdForAdConfiguration:(GADMediationNativeAdConfiguration *)adConfiguration
                     completionHandler:(GADMediationNativeLoadCompletionHandler)completionHandler;

@end

#endif /* ADMCustomEventNativeAd_h */