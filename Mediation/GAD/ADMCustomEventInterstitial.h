//
//  ADMCustomEventInterstitial.h
//  GADMediationAdMaster
//
//  Created by AdMasterDev on 2025/8/25.
//

#ifndef ADMCustomEventInterstitial_h
#define ADMCustomEventInterstitial_h

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface ADMCustomEventInterstitial : NSObject

- (void)loadInterstitialForAdConfiguration:(GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:(GADMediationInterstitialLoadCompletionHandler)completionHandler;

@end

#endif /* ADMCustomEventInterstitial_h */