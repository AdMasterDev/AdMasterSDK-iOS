//
//  ADMCustomEventInterstitial.m
//  GADMediationAdMaster
//

#import "ADMCustomEventInterstitial.h"
#import "ADMCustomEventUtils.h"
#import "ADMCustomEventConstants.h"
#import <AdMasterSDK/AdMasterSDK.h>
#include <stdatomic.h>

@interface ADMCustomEventInterstitial () <ADMInterstitialDelegate, ADMFullScreenContentDelegate, GADMediationInterstitialAd> {
    ADMInterstitialAd *_interstitialAd;
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
    [ADMCustomEventUtils updateAdMasterRuntimeFromAdConfigurationParameter:parameter];
    NSString *adUnitID = [ADMCustomEventUtils adUnitIDFromAdConfigurationParameter:parameter];
    if (!adUnitID) {
        NSError *error = [ADMCustomEventUtils errorWithCode:ADMCustomEventErrorInvalidAdUnitID
                                                description:@"Missing ad_unit_id in configuration"];
        _adEventDelegate = _loadCompletionHandler(nil, error);
        return;
    }

    _interstitialAd = [[ADMInterstitialAd alloc] init];
    _interstitialAd.adUnitTag = adUnitID;
    _interstitialAd.delegate = self;
    _interstitialAd.fullScreenContentDelegate = self;
    [_interstitialAd load];
}

- (void)presentFromViewController:(UIViewController *)viewController {
    if ([_interstitialAd isReady]) {
        [_interstitialAd presentFromViewController:viewController];
    } else {
        NSError *error = [ADMCustomEventUtils errorWithCode:ADMCustomEventErrorAdNotReady
                                                description:@"The interstitial ad failed to present because the ad was not ready."];
        [_adEventDelegate didFailToPresentWithError:error];
    }
}

#pragma mark - ADMInterstitialDelegate

- (void)interstitialAdDidReceiveAd:(ADMInterstitialAd *)ad {
    _adEventDelegate = _loadCompletionHandler(self, nil);
}

- (void)interstitialAd:(ADMInterstitialAd *)ad didFailToReceiveAdWithError:(NSError *)error {
    NSError *err = [ADMCustomEventUtils errorWithCode:ADMCustomEventErrorAdLoadFailed
                                         description:error.localizedDescription];
    _adEventDelegate = _loadCompletionHandler(nil, err);
}

- (void)adWillPresentFullScreenContent:(id)ad {
    [_adEventDelegate willPresentFullScreenView];
}

- (void)adDidRecordImpression:(id)ad {
    [_adEventDelegate reportImpression];
}

- (void)ad:(id)ad didFailToPresentFullScreenContentWithError:(NSError *)error {
    NSError *err = [ADMCustomEventUtils errorWithCode:ADMCustomEventErrorAdPresentFailed
                                         description:error.localizedDescription];
    [_adEventDelegate didFailToPresentWithError:err];
}

- (void)adWillDismissFullScreenContent:(id)ad {
}

- (void)adDidDismissFullScreenContent:(id)ad {
    [_adEventDelegate didDismissFullScreenView];
}

- (void)adDidRecordClick:(id)ad {
    [_adEventDelegate reportClick];
}

@end
