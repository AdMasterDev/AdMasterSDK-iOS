//
//  ADMCustomEventBanner.m
//  GADMediationAdMaster
//
//  Created by AdMasterDev on 2025/8/25.
//

#import "ADMCustomEventBanner.h"
#import "ADMCustomEventUtils.h"
#import "ADMCustomEventConstants.h"
#import <AdMasterSDK/AdMasterSDK.h>
#include <stdatomic.h>

@interface ADMCustomEventBanner () <ADMBannerDelegate, GADMediationBannerAd> {
    ADMBannerView *_bannerAd;
    GADMediationBannerLoadCompletionHandler _loadCompletionHandler;
    __weak id<GADMediationBannerAdEventDelegate> _adEventDelegate;
}
@end

@implementation ADMCustomEventBanner

- (void)loadBannerForAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler {
    __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationBannerLoadCompletionHandler originalCompletionHandler = [completionHandler copy];
    
    _loadCompletionHandler = ^id<GADMediationBannerAdEventDelegate>(_Nullable id<GADMediationBannerAd> ad, NSError *_Nullable error) {
        if (atomic_flag_test_and_set(&completionHandlerCalled)) {
            return nil;
        }
        id<GADMediationBannerAdEventDelegate> delegate = nil;
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
    
    CGSize adSize = CGSizeMake(adConfiguration.adSize.size.width, adConfiguration.adSize.size.height);
    _bannerAd = [[ADMBannerView alloc] initWithAdSize:adSize adUnitTag:adUnitID];
    _bannerAd.delegate = self;
    [_bannerAd loadAd];
}

#pragma mark GADMediationBannerAd implementation

- (nonnull UIView *)view {
    return _bannerAd;
}

#pragma mark ADMBannerDelegate implementation

- (void)bannerViewDidLoadAd:(ADMBannerView *)bannerView {
    _adEventDelegate = _loadCompletionHandler(self, nil);
}

- (void)bannerView:(ADMBannerView *)bannerView didFailToLoadAdWithError:(NSError *)error {
    NSError *adError = [ADMCustomEventUtils errorWithCode:ADMCustomEventErrorAdLoadFailed description:error.localizedDescription];
    _adEventDelegate = _loadCompletionHandler(nil, adError);
}

- (void)bannerView:(ADMBannerView *)bannerView didFailToDisplayAdWithError:(NSError *)error {
    NSError *adError = [ADMCustomEventUtils errorWithCode:ADMCustomEventErrorAdPresentFailed description:error.localizedDescription];
    [_adEventDelegate didFailToPresentWithError:adError];
}

- (void)bannerViewDidImpression:(ADMBannerView *)bannerView {
    [_adEventDelegate reportImpression];
}

- (void)bannerViewDidClick:(ADMBannerView *)bannerView {
    [_adEventDelegate reportClick];
}

- (void)bannerViewDidClose:(ADMBannerView *)bannerView {}

@end
