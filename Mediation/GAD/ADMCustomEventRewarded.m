//
//  ADMCustomEventRewarded.m
//  GADMediationAdMaster
//

#import "ADMCustomEventRewarded.h"
#import "ADMCustomEventUtils.h"
#import "ADMCustomEventConstants.h"
#import <AdMasterSDK/AdMasterSDK.h>
#include <stdatomic.h>

@interface ADMCustomEventRewarded () <ADMRewardedDelegate, ADMFullScreenContentDelegate, GADMediationRewardedAd> {
    ADMRewardedAd *_rewardedAd;
    GADMediationRewardedLoadCompletionHandler _loadCompletionHandler;
    __weak id<GADMediationRewardedAdEventDelegate> _adEventDelegate;
    BOOL _didEarnReward;
}
@end

@implementation ADMCustomEventRewarded

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:(GADMediationRewardedLoadCompletionHandler)completionHandler {
    _didEarnReward = NO;
    __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationRewardedLoadCompletionHandler originalCompletionHandler = [completionHandler copy];

    _loadCompletionHandler = ^id<GADMediationRewardedAdEventDelegate>(_Nullable id<GADMediationRewardedAd> ad, NSError *_Nullable error) {
        if (atomic_flag_test_and_set(&completionHandlerCalled)) {
            return nil;
        }
        id<GADMediationRewardedAdEventDelegate> delegate = nil;
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

    _rewardedAd = [[ADMRewardedAd alloc] init];
    _rewardedAd.adUnitTag = adUnitID;
    _rewardedAd.delegate = self;
    _rewardedAd.fullScreenContentDelegate = self;
    [_rewardedAd load];
}

- (void)presentFromViewController:(UIViewController *)viewController {
    if ([_rewardedAd isReady]) {
        [_rewardedAd presentFromViewController:viewController];
    } else {
        NSError *error = [ADMCustomEventUtils errorWithCode:ADMCustomEventErrorAdNotReady
                                                description:@"The rewarded ad failed to present because the ad was not ready."];
        [_adEventDelegate didFailToPresentWithError:error];
    }
}

#pragma mark - ADMRewardedDelegate

- (void)rewardedAdDidReceiveAd:(ADMRewardedAd *)ad {
    _adEventDelegate = _loadCompletionHandler(self, nil);
}

- (void)rewardedAd:(ADMRewardedAd *)ad didFailToReceiveAdWithError:(NSError *)error {
    NSError *err = [ADMCustomEventUtils errorWithCode:ADMCustomEventErrorAdLoadFailed
                                         description:error.localizedDescription];
    _adEventDelegate = _loadCompletionHandler(nil, err);
}

- (void)rewardedAd:(ADMRewardedAd *)ad userDidEarnReward:(ADMReward *)reward {
    _didEarnReward = YES;
    [_adEventDelegate didRewardUser];
}

- (void)rewardedAdDidCompleteVideo:(ADMRewardedAd *)ad {
    [_adEventDelegate didEndVideo];
}

- (void)adWillPresentFullScreenContent:(id)ad {
    [_adEventDelegate willPresentFullScreenView];
    [_adEventDelegate didStartVideo];
}

- (void)adDidRecordImpression:(id)ad {
    [_adEventDelegate reportImpression];
}

- (void)ad:(id)ad didFailToPresentFullScreenContentWithError:(NSError *)error {
    NSError *err = [ADMCustomEventUtils errorWithCode:ADMCustomEventErrorAdPresentFailed
                                         description:error.localizedDescription];
    [_adEventDelegate didFailToPresentWithError:err];
}

- (void)adDidDismissFullScreenContent:(id)ad {
    [_adEventDelegate didDismissFullScreenView];
}

- (void)adDidRecordClick:(id)ad {
    [_adEventDelegate reportClick];
}

@end
