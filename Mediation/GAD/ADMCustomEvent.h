//
//  ADMCustomEvent.h
//  GADMediationAdMaster
//
//  Created by AdMasterDev on 2025/8/25.
//

#ifndef ADMCustomEvent_h
#define ADMCustomEvent_h

#import <Foundation/Foundation.h>
#if __has_include(<GoogleMobileAds/GoogleMobileAds.h>)
#import <GoogleMobileAds/GoogleMobileAds.h>
#else
@protocol GADMediationAdapter <NSObject>
@end
@interface GADMediationCredentials : NSObject
@property (nonatomic, readonly, nonnull) NSDictionary<NSString *, id> *settings;
@end
@interface GADMediationAdConfiguration : NSObject
@property (nonatomic, readonly, nonnull) GADMediationCredentials *credentials;
@end
#endif

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

#endif /* ADMCustomEvent_h */