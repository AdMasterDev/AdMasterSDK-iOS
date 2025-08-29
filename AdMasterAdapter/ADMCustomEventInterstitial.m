//
//  ADMCustomEventInterstitial.m
//  GADMediationAdMaster
//
//  Created by AdMasterDev on 2025/8/25.
//

#import "ADMCustomEventInterstitial.h"
#import "ADMCustomEventUtils.h"
#import "ADMCustomEventConstants.h"
#import <AdMasterSDK/AdMasterSDK.h>
#include <stdatomic.h>

@interface ADMCustomEventInterstitial () <ADMExpressIntDelegate, GADMediationInterstitialAd> {
    ADMExpressInterstitial *_interstitialAd;
    GADMediationInterstitialLoadCompletionHandler _loadCompletionHandler;
    __weak id<GADMediationInterstitialAdEventDelegate> _adEventDelegate;
}
@end

@implementation ADMCustomEventInterstitial

- (void)loadInterstitialForAdConfiguration:(GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:(GADMediationInterstitialLoadCompletionHandler)completionHandler {
    __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationInterstitialLoadCompletionHandler originalCompletionHandler = [completionHandler copy];
    
    _loadCompletionHandler = ^id<GADMediationInterstitialAdEventDelegate>(_Nullable id<GADMediationInterstitialAd> ad, NSError *_Nullable error) {
        if (atomic_flag_test_and_set(&completionHandlerCalled)) {
            return nil;
        }
        id<GADMediationInterstitialAdEventDelegate> delegate = nil;
        if (originalCompletionHandler) {
            delegate = originalCompletionHandler(ad, error);
        }
        originalCompletionHandler = nil;
        return delegate;
    };
    
    NSString *parameter = adConfiguration.credentials.settings[@"parameter"];
    NSString *adUnitID = [ADMCustomEventUtils adUnitIDFromAdConfigurationParameter:parameter];
    if (!adUnitID) {
        NSError *error = [ADMCustomEventUtils errorWithCode:ADMCustomEventErrorInvalidAdUnitID
                                                description:@"Missing ad_unit_id in configuration"];
        _adEventDelegate = _loadCompletionHandler(nil, error);
        return;
    }
    
    _interstitialAd = [[ADMExpressInterstitial alloc] init];
    _interstitialAd.adUnitTag = adUnitID;
    _interstitialAd.delegate = self;
    [_interstitialAd load];
}

#pragma mark GADMediationInterstitialAd implementation

- (void)presentFromViewController:(UIViewController *)viewController {
    if ([_interstitialAd isReady]) {
        [_interstitialAd showFromViewController:viewController];
    } else {
        NSError *error = [ADMCustomEventUtils errorWithCode:ADMCustomEventErrorAdNotReady
                                                description:@"The interstitial ad failed to present because the ad was not loaded."];
        _adEventDelegate = _loadCompletionHandler(self, error);
    }
}

#pragma mark ADMExpressIntDelegate implementation

- (void)interstitialAdLoaded:(ADMExpressInterstitial *)interstitial {
    _adEventDelegate = _loadCompletionHandler(self, nil);
}

- (void)interstitialAdLoadFailCode:(NSString *)errCode
                           message:(NSString *)message
                    interstitialAd:(ADMExpressInterstitial *)interstitial {
    NSError *error = [ADMCustomEventUtils errorWithCode:ADMCustomEventErrorAdLoadFailed
                                            description:[NSString stringWithFormat:@"The interstitial ad load failure callback with error code: %@, message: %@", errCode, message]];
    _adEventDelegate = _loadCompletionHandler(nil, error);
}

- (void)interstitialAdExposure:(ADMExpressInterstitial *)interstitial {
    [_adEventDelegate willPresentFullScreenView];
}

- (void)interstitialAdExposureFail:(ADMExpressInterstitial *)interstitial withError:(int)reason {
    NSError *err = [ADMCustomEventUtils errorWithCode:ADMCustomEventErrorAdPresentFailed
                                          description:[NSString stringWithFormat:@"The interstitial ad failed to present with error code: %d", reason]];
    _adEventDelegate = _loadCompletionHandler(nil, err);
}

- (void)interstitialAdDidClose:(ADMExpressInterstitial *)interstitial {
    [_adEventDelegate willDismissFullScreenView];
    [_adEventDelegate didDismissFullScreenView];
}

- (void)interstitialAdDidClick:(ADMExpressInterstitial *)interstitial {
    [_adEventDelegate reportClick];
}


- (void)interstitialAdImpressed:(ADMExpressInterstitial *)interstitial {
    [_adEventDelegate reportImpression];
}

- (void)interstitialAdDownloadSucceeded:(ADMExpressInterstitial *)interstitial {}

- (void)interstitialAdDownLoadFailed:(ADMExpressInterstitial *)interstitial {
    NSError *err = [ADMCustomEventUtils errorWithCode:ADMCustomEventErrorAdLoadFailed description:@"The interstitial ad failed to load."];
    _adEventDelegate = _loadCompletionHandler(nil, err);
}

- (void)interstitialAdVideoPlayFailed:(ADMExpressInterstitial *)interstitial WithError:(NSString *)error {
    NSError *err = [ADMCustomEventUtils errorWithCode:ADMCustomEventErrorAdVideoPlayFailed description:error];
    _adEventDelegate = _loadCompletionHandler(nil, err);
}

@end
