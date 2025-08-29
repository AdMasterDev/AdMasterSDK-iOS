//
//  ADMCustomEvent.h
//  GADMediationAdMaster
//
//  Created by AdMasterDev on 2025/8/25.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

typedef NS_ENUM(NSInteger, ADMCustomEventErrorCode) {
    ADMCustomEventErrorInvalidConfiguration = 100,
    ADMCustomEventErrorInvalidAppID = 101,
    ADMCustomEventErrorInvalidAdUnitID = 102,
    ADMCustomEventErrorAdLoadFailed = 103,
    ADMCustomEventErrorAdNotReady = 104,
    ADMCustomEventErrorAdPresentFailed = 105,
    ADMCustomEventErrorAdVideoPlayFailed = 106
};

@interface ADMCustomEvent : NSObject <GADMediationAdapter>

@end
