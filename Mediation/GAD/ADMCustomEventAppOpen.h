//
//  ADMCustomEventAppOpen.h
//  GADMediationAdMaster
//

#ifndef ADMCustomEventAppOpen_h
#define ADMCustomEventAppOpen_h

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface ADMCustomEventAppOpen : NSObject

- (void)loadAppOpenAdForAdConfiguration:(GADMediationAppOpenAdConfiguration *)adConfiguration
                      completionHandler:(GADMediationAppOpenLoadCompletionHandler)completionHandler;

@end

#endif /* ADMCustomEventAppOpen_h */
