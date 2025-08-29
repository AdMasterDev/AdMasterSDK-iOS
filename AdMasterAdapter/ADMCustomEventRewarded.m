//
//  ADMCustomEventRewarded.m
//  GADMediationAdMaster
//
//  Created by AdMasterDev on 2025/8/25.
//

#import "ADMCustomEventRewarded.h"
#import "ADMCustomEventUtils.h"
#import "ADMCustomEventConstants.h"
#import <AdMasterSDK/AdMasterSDK.h>
#include <stdatomic.h>

@interface ADMCustomEventRewarded () <ADMRewardVideoDelegate, GADMediationRewardedAd> {
    ADMRewardVideo *_rewardedAd;
    GADMediationRewardedLoadCompletionHandler _loadCompletionHandler;
    __weak id<GADMediationRewardedAdEventDelegate> _adEventDelegate;
}
@end

@implementation ADMCustomEventRewarded

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:(GADMediationRewardedLoadCompletionHandler)completionHandler {
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
    NSString *adUnitID = [ADMCustomEventUtils adUnitIDFromAdConfigurationParameter:parameter];
    if (!adUnitID) {
        NSError *error = [ADMCustomEventUtils errorWithCode:ADMCustomEventErrorInvalidAdUnitID
                                                description:@"Missing ad_unit_id in configuration"];
        _adEventDelegate = _loadCompletionHandler(nil, error);
        return;
    }
    
    _rewardedAd = [[ADMRewardVideo alloc] init];
    _rewardedAd.adUnitTag = adUnitID;
    _rewardedAd.delegate = self;
    [_rewardedAd load];
}

#pragma mark GADMediationRewardedAd implementation

- (void)presentFromViewController:(UIViewController *)viewController {
    if ([_rewardedAd isReady]) {
        [_rewardedAd showFromViewController:viewController];
    } else {
        NSError *error = [ADMCustomEventUtils errorWithCode:ADMCustomEventErrorAdNotReady
                                                description:@"The rewarded ad failed to present because the ad was not ready."];
        _adEventDelegate = _loadCompletionHandler(self, error);
    }
}

#pragma mark ADMRewardVideoDelegate implementation

- (void)rewardedAdLoadSuccess:(ADMRewardVideo *)video {}

- (void)rewardedAdLoadFailCode:(NSString *)errCode message:(NSString *)message rewardedAd:(ADMRewardVideo *)video {
    NSError *error = [ADMCustomEventUtils errorWithCode:ADMCustomEventErrorAdLoadFailed
                                            description:[NSString stringWithFormat:@"The rewarded ad load failure callback with error code: %@, message: %@", errCode, message]];
    _adEventDelegate = _loadCompletionHandler(nil, error);
}

- (void)rewardedVideoAdLoaded:(ADMRewardVideo *)video {
    _adEventDelegate = _loadCompletionHandler(self, nil);
}

- (void)rewardedVideoAdLoadFailed:(ADMRewardVideo *)video withError:(ADMFailReason)reason {
    NSError *error = [ADMCustomEventUtils errorWithCode:ADMCustomEventErrorAdLoadFailed
                                            description:[NSString stringWithFormat:@"The rewarded ad load failure callback with error code:%u", reason]];
    _adEventDelegate = _loadCompletionHandler(nil, error);
}

- (void)rewardedVideoAdShowFailed:(ADMRewardVideo *)video withError:(ADMFailReason)reason {
    NSError *error = [ADMCustomEventUtils errorWithCode:ADMCustomEventErrorAdPresentFailed
                                            description:[NSString stringWithFormat:@"The rewarded ad present failure callback with error code:%u", reason]];
    [_adEventDelegate didFailToPresentWithError:error];
}

- (void)rewardedVideoAdPlayFailed:(ADMRewardVideo *)video withError:(NSString *)error{
    NSError *err = [ADMCustomEventUtils errorWithCode:ADMCustomEventErrorAdVideoPlayFailed
                                            description:[NSString stringWithFormat:@"The rewarded ad video play failure callback with error :%@", error]];
    [_adEventDelegate didFailToPresentWithError:err];
}

- (void)rewardedVideoAdDidExposured:(ADMRewardVideo *)video {
    [_adEventDelegate reportImpression];
}

- (void)rewardedVideoAdDidStarted:(ADMRewardVideo *)video {
    [_adEventDelegate willPresentFullScreenView];
    [_adEventDelegate didStartVideo];
}

- (void)rewardedVideoAdDidPlayFinish:(ADMRewardVideo *)video {
    [_adEventDelegate didRewardUser];
    [_adEventDelegate didEndVideo];
}

- (void)rewardedVideoAdDidClick:(ADMRewardVideo *)video withPlayingProgress:(CGFloat)progress {
    [_adEventDelegate reportClick];
}

- (void)rewardedVideoAdDidClose:(ADMRewardVideo *)video withPlayingProgress:(CGFloat)progress {
    [_adEventDelegate didDismissFullScreenView];
}

- (void)rewardedVideoAdWillClose:(ADMRewardVideo *)video withPlayingProgress:(CGFloat)progress {
    [_adEventDelegate willDismissFullScreenView];
}

- (void)rewardedVideoAdDidSkip:(ADMRewardVideo *)video withPlayingProgress:(CGFloat)progress {
}
@end
