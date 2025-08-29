//
//  ADMCustomEvent.m
//  GADMediationAdMaster
//
//  Created by AdMasterDev on 2025/8/25.
//

#import "ADMCustomEvent.h"
#import "ADMCustomEventBanner.h"
#import "ADMCustomEventInterstitial.h"
#import "ADMCustomEventRewarded.h"
#import "ADMCustomEventNativeAd.h"
#import "ADMCustomEventUtils.h"
#import "ADMCustomEventConstants.h"
#import <AdMasterSDK/AdMasterSDK.h>

@implementation ADMCustomEvent {
    ADMCustomEventRewarded *admRewarded;
    ADMCustomEventBanner *admBanner;
    ADMCustomEventNativeAd *admNative;
    ADMCustomEventInterstitial *admInterstitial;
}

#pragma mark GADMediationAdapter implementation

+ (GADVersionNumber)adSDKVersion {
    NSArray *versionComponents = [[ADMManager getSDKVersion] componentsSeparatedByString:@"."];
    GADVersionNumber version = {0};
    if (versionComponents.count >= 3) {
        version.majorVersion = [versionComponents[0] integerValue];
        version.minorVersion = [versionComponents[1] integerValue];
        version.patchVersion = [versionComponents[2] integerValue];
    }
    return version;
}

+ (GADVersionNumber)adapterVersion {
    NSArray *versionComponents = [ADMCustomEventAdapterVersion componentsSeparatedByString:@"."];
    GADVersionNumber version = {0};
    if (versionComponents.count == 4) {
        version.majorVersion = [versionComponents[0] integerValue];
        version.minorVersion = [versionComponents[1] integerValue];
        version.patchVersion =
        [versionComponents[2] integerValue] * 100 + [versionComponents[3] integerValue];
    }
    return version;
}

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
    return Nil;
}

+ (void)setUpWithConfiguration:(GADMediationServerConfiguration *)configuration
             completionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {
    if (configuration.credentials.count == 0) {
        NSError *error = [ADMCustomEventUtils errorWithCode:ADMCustomEventErrorInvalidConfiguration
                                                description:@"Missing configuration"];
        completionHandler(error);
        return;
    }
    NSString *parameter = configuration.credentials.firstObject.settings[@"parameter"];
    NSString *appID = [ADMCustomEventUtils appIDFromAdConfigurationParameter:parameter];
    if (!appID) {
        NSError *error = [ADMCustomEventUtils errorWithCode:ADMCustomEventErrorInvalidAppID
                                                description:@"Missing app_id in configuration"];
        completionHandler(error);
        return;
    }
    
    [ADMManager startWithAppsid:appID completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            completionHandler(nil);
        } else {
            completionHandler(error);
        }
    }];
    
    BOOL isTestMode = [ADMCustomEventUtils isTestFromAdConfigurationParameter: parameter];
    if (isTestMode) {
        [ADMSetting sharedInstance].isTest = YES;
    }
}

- (void)loadBannerForAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler {
    admBanner = [[ADMCustomEventBanner alloc] init];
    [admBanner loadBannerForAdConfiguration:adConfiguration completionHandler:completionHandler];
}

- (void)loadInterstitialForAdConfiguration:(GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:(GADMediationInterstitialLoadCompletionHandler)completionHandler {
    admInterstitial = [[ADMCustomEventInterstitial alloc] init];
    [admInterstitial loadInterstitialForAdConfiguration:adConfiguration
                                      completionHandler:completionHandler];
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:(GADMediationRewardedLoadCompletionHandler)completionHandler {
    admRewarded = [[ADMCustomEventRewarded alloc] init];
    [admRewarded loadRewardedAdForAdConfiguration:adConfiguration
                                completionHandler:completionHandler];
}

- (void)loadNativeAdForAdConfiguration:(GADMediationNativeAdConfiguration *)adConfiguration
                     completionHandler:(GADMediationNativeLoadCompletionHandler)completionHandler {
    admNative = [[ADMCustomEventNativeAd alloc] init];
    [admNative loadNativeAdForAdConfiguration:adConfiguration completionHandler:completionHandler];
}

@end
