//
//  ADMCustomEventAppOpen.m
//  GADMediationAdMaster
//

#import "ADMCustomEventAppOpen.h"
#import "ADMCustomEventUtils.h"
#import "ADMCustomEventConstants.h"
#import <AdMasterSDK/AdMasterSDK.h>
#include <stdatomic.h>

@interface ADMCustomEventAppOpen () <ADMFullScreenContentDelegate, ADMSplashDelegate, GADMediationAppOpenAd> {
    ADMSplashAd *_splashAd;
    UIView *_containerView;
    GADMediationAppOpenLoadCompletionHandler _loadCompletionHandler;
    __weak id<GADMediationAppOpenAdEventDelegate> _adEventDelegate;
}
@end

@implementation ADMCustomEventAppOpen

- (void)loadAppOpenAdForAdConfiguration:(GADMediationAppOpenAdConfiguration *)adConfiguration
                      completionHandler:(GADMediationAppOpenLoadCompletionHandler)completionHandler {
    __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationAppOpenLoadCompletionHandler originalCompletionHandler = [completionHandler copy];
    
    _loadCompletionHandler = ^id<GADMediationAppOpenAdEventDelegate>(_Nullable id<GADMediationAppOpenAd> ad, NSError *_Nullable error) {
        if (atomic_flag_test_and_set(&completionHandlerCalled)) {
            return nil;
        }
        id<GADMediationAppOpenAdEventDelegate> delegate = nil;
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
    
    _splashAd = [[ADMSplashAd alloc] init];
    _splashAd.adUnitTag = adUnitID;
    _splashAd.adSize = [UIScreen mainScreen].bounds.size;
    _splashAd.delegate = self;
    _splashAd.fullScreenContentDelegate = self;
    [_splashAd load];
}

- (void)presentFromViewController:(UIViewController *)viewController {
    if (![_splashAd isReady]) {
        NSError *error = [ADMCustomEventUtils errorWithCode:ADMCustomEventErrorAdNotReady
                                                description:@"The app open ad failed to present because the ad was not ready."];
        [_adEventDelegate didFailToPresentWithError:error];
        return;
    }
    
    UIView *presentingView = viewController.view.window ?: viewController.view ?: viewController.navigationController.view;
    if (!presentingView) {
        NSError *error = [ADMCustomEventUtils errorWithCode:ADMCustomEventErrorAdPresentFailed
                                                description:@"The app open ad failed to present because presenting view is nil."];
        [_adEventDelegate didFailToPresentWithError:error];
        return;
    }
    
    _containerView = [[UIView alloc] initWithFrame:presentingView.bounds];
    _containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [presentingView addSubview:_containerView];
    [_splashAd presentInContainerView:_containerView presentingViewController:viewController];
}

#pragma mark - ADMSplashDelegate

- (void)splashAdDidReceiveAd:(ADMSplashAd *)splashAd {
    _adEventDelegate = _loadCompletionHandler(self, nil);
}

- (void)splashAd:(ADMSplashAd *)splashAd didFailToReceiveAdWithError:(NSError *)error {
    NSError *adError = [ADMCustomEventUtils errorWithCode:ADMCustomEventErrorAdLoadFailed
                                              description:error.localizedDescription ?: @"App open ad load failed"];
    _adEventDelegate = _loadCompletionHandler(nil, adError);
}

#pragma mark - ADMFullScreenContentDelegate

- (void)adWillPresentFullScreenContent:(id)ad {
    [_adEventDelegate willPresentFullScreenView];
}

- (void)adDidRecordImpression:(id)ad {
    [_adEventDelegate reportImpression];
}

- (void)ad:(id)ad didFailToPresentFullScreenContentWithError:(NSError *)error {
    [_containerView removeFromSuperview];
    _containerView = nil;
    NSError *adError = [ADMCustomEventUtils errorWithCode:ADMCustomEventErrorAdPresentFailed
                                              description:error.localizedDescription ?: @"App open ad present failed"];
    [_adEventDelegate didFailToPresentWithError:adError];
}

- (void)adWillDismissFullScreenContent:(id)ad {
    [_adEventDelegate willDismissFullScreenView];
}

- (void)adDidDismissFullScreenContent:(id)ad {
    [_containerView removeFromSuperview];
    _containerView = nil;
    [_adEventDelegate didDismissFullScreenView];
}

- (void)adDidRecordClick:(id)ad {
    [_adEventDelegate reportClick];
}

@end
