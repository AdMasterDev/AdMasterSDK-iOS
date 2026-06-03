//
//  ADMCustomEventNativeAd.m
//  GADMediationAdMaster
//
//  Created by AdMasterDev on 2025/8/25.
//

#import "ADMCustomEventNativeAd.h"
#import "ADMCustomEventUtils.h"
#import "ADMCustomEventConstants.h"
#import <AdMasterSDK/AdMasterSDK.h>

#include <stdatomic.h>

static NSURL *ADMCustomEventURLWithString(NSString *string) {
    if (string.length == 0) {
        return nil;
    }
    NSURL *url = [NSURL URLWithString:string];
    if (!url) {
        NSString *encodedString = [string stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        url = [NSURL URLWithString:encodedString];
    }
    return url;
}

@interface ADMCustomEventNativeAd () <ADMNativeAdLoaderDelegate, ADMNativeInteractionDelegate, ADMNativeVideoViewDelegate, GADMediationNativeAd> {
    __weak id<GADMediationNativeAdEventDelegate> _adEventDelegate;
    GADMediationNativeLoadCompletionHandler _loadCompletionHandler;
    GADNativeAdViewAdOptions *_nativeAdViewAdOptions;
    
    ADMNativeAdLoader *_nativeAd;
    ADMNativeAdObject *_nativeAdObject;
    ADMNativeVideoView *_nativeVideoView;
    
    NSArray<GADNativeAdImage *> *_images;
    GADNativeAdImage *_icon;
    UIView *_adChoicesView;
}
@end

@implementation ADMCustomEventNativeAd

#pragma mark GADMediatedUnifiedNativeAd implementation

- (nullable NSString *)headline {
    return _nativeAdObject.title;
}

- (NSArray<GADNativeAdImage *> *)images {
    return _images;
}

- (nullable NSString *)body {
    return _nativeAdObject.text;
}

- (GADNativeAdImage *)icon {
    return _icon;
}

- (nullable NSString *)callToAction {
    return _nativeAdObject.actButtonString;
}

- (NSDecimalNumber *)starRating {
    return nil;
}

- (nullable NSString *)store {
    return nil;
}

- (nullable NSString *)price {
    return [_nativeAdObject getECPMLevel];
}

- (nullable NSString *)advertiser {
    return _nativeAdObject.brandName;
}

- (nullable NSDictionary<NSString *, id> *)extraAssets {
    return nil;
}

- (nullable UIView *)adChoicesView {
    return _adChoicesView;
}

- (UIView *)mediaView {
    return _nativeVideoView;
}

- (BOOL)hasVideoContent {
    return _nativeAdObject.materialType == VIDEO;
}

- (CGFloat)mediaContentAspectRatio {
    return _nativeAdObject.aspectRatio ?: 1.91;
}

- (void)didRenderInView:(UIView *)view
    clickableAssetViews:(NSDictionary<GADNativeAssetIdentifier, UIView *> *)clickableAssetViews
 nonclickableAssetViews:(NSDictionary<GADNativeAssetIdentifier, UIView *> *)nonclickableAssetViews
         viewController:(UIViewController *)viewController {
    if (_nativeAdObject) {
        NSArray<UIView *> *assets = clickableAssetViews.allValues;
        UIView *mediaView = self.mediaView ?: view;
        [_nativeAdObject registerViewForInteraction:view
                                          mediaView:mediaView
                                     clickableViews:assets
                                     viewController:viewController];
    }
}

- (void)didUntrackView:(UIView *)view {
    if (_nativeAdObject) {
        [_nativeAdObject unregisterView:view];
    }
}

- (void)didRecordImpression {}

- (void)didRecordClickOnAssetWithName:(GADNativeAssetIdentifier)assetName view:(UIView *)view viewController:(UIViewController *)viewController {}


#pragma mark GADMediationNativeAd implementation

- (BOOL)handlesUserClicks {
    return YES;
}

- (BOOL)handlesUserImpressions {
    return YES;
}

#pragma mark ADMCustomEventNativeAd

- (void)loadNativeAdForAdConfiguration:(GADMediationNativeAdConfiguration *)adConfiguration
                     completionHandler:(GADMediationNativeLoadCompletionHandler)completionHandler {
    __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationNativeLoadCompletionHandler originalCompletionHandler = [completionHandler copy];
    
    _loadCompletionHandler = ^id<GADMediationNativeAdEventDelegate>(_Nullable id<GADMediationNativeAd> ad, NSError *_Nullable error) {
        if (atomic_flag_test_and_set(&completionHandlerCalled)) {
            return nil;
        }
        id<GADMediationNativeAdEventDelegate> delegate = nil;
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
    
    _nativeAd = [[ADMNativeAdLoader alloc] init];
    _nativeAd.adUnitTag = adUnitID;
    _nativeAd.delegate = self;
    [_nativeAd load];
}

#pragma mark ADMNativeAdLoaderDelegate

- (void)nativeAdLoader:(ADMNativeAdLoader *)loader didReceiveNativeAds:(NSArray<ADMNativeAdObject *> *)nativeAds {
    if (!nativeAds || nativeAds.count == 0 || [nativeAds.firstObject isExpired]) {
        NSError *error = [ADMCustomEventUtils errorWithCode:ADMCustomEventErrorAdLoadFailed
                                                description:@"No valid native ad object received"];
        _adEventDelegate = _loadCompletionHandler(nil, error);
        return;
    }
    _nativeAdObject = nativeAds.firstObject;
    _nativeAdObject.interactionDelegate = self;
    
    dispatch_group_t group = dispatch_group_create();
    __block GADNativeAdImage *loadedIcon = nil;
    __block GADNativeAdImage *loadedImage = nil;
    
    dispatch_group_enter(group);
    __weak typeof(self) weakSelf = self;
    [self loadImageFromURL:_nativeAdObject.iconImageURLString completion:^(GADNativeAdImage * _Nullable gadImage) {
        loadedIcon = gadImage;
        dispatch_group_leave(group);
    }];
    
    if (_nativeAdObject.materialType != VIDEO) {
        dispatch_group_enter(group);
        [weakSelf loadImageFromURL:_nativeAdObject.mainImageURLString completion:^(GADNativeAdImage * _Nullable gadImage) {
            loadedImage = gadImage;
            dispatch_group_leave(group);
        }];
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        strongSelf->_icon = loadedIcon;
        strongSelf->_images = (loadedImage == nil) ? @[] : @[loadedImage];
        strongSelf->_nativeVideoView = nil;
        if (strongSelf->_nativeAdObject.materialType == VIDEO) {
            strongSelf->_nativeVideoView = [[ADMNativeVideoView alloc] initWithFrame:CGRectZero andObject:strongSelf->_nativeAdObject];
            strongSelf->_nativeVideoView.videoDelegate = strongSelf;
        }
        strongSelf->_adEventDelegate = strongSelf->_loadCompletionHandler(strongSelf, nil);
    });
}

- (void)nativeAdLoader:(ADMNativeAdLoader *)loader
didFailToReceiveAdWithError:(NSError *)error
          nativeAdObject:(ADMNativeAdObject *)adObject {
    NSError *err = [ADMCustomEventUtils errorWithCode:ADMCustomEventErrorAdLoadFailed
                                         description:error.localizedDescription];
    _adEventDelegate = _loadCompletionHandler(nil, err);
}

- (void)nativeAd:(ADMNativeAdObject *)ad didRecordClickForView:(UIView *)view {
    [_adEventDelegate reportClick];
}

- (void)nativeAd:(ADMNativeAdObject *)ad didDismissLandingPageFromView:(UIView *)view {
    (void)ad;
    (void)view;
}

- (void)nativeAd:(ADMNativeAdObject *)ad didRecordImpressionForView:(UIView *)view {
    [_adEventDelegate reportImpression];
}

- (void)nativeAd:(ADMNativeAdObject *)ad didFailToRecordImpressionForView:(UIView *)view error:(NSError *)error {
    // GAD Mediation native API has no dedicated exposure-fail callback; do not report impression.
    (void)ad;
    (void)view;
    (void)error;
}

#pragma mark ADMNativeVideoViewDelegate implementation

- (void)nativeVideoAdDidStartPlaying:(ADMNativeVideoView *)videoView {
    [_adEventDelegate didPlayVideo];
}

- (void)nativeVideoAdDidPause:(ADMNativeVideoView *)videoView {
    [_adEventDelegate didPauseVideo];
}

- (void)nativeVideoAdDidReplay:(ADMNativeVideoView *)videoView {
    [_adEventDelegate didPlayVideo];
}

- (void)nativeVideoAdDidComplete:(ADMNativeVideoView *)videoView {
    [_adEventDelegate didEndVideo];
}

#pragma mark Load Native Image

- (void)loadImageFromURL:(NSString *)urlString completion:(void(^)(GADNativeAdImage * _Nullable gadImage))completion {
    if (urlString == nil) {
        if (completion) {
            completion(nil);
        }
        return;
    }
    NSURL *url = ADMCustomEventURLWithString(urlString);
    if (!url) {
        if (completion) {
            completion(nil);
        }
        return;
    }
    [_nativeAdObject loadImageWithURLString:urlString completion:^(UIImage * _Nullable image) {
        if (!image) {
            if (completion) {
                completion([[GADNativeAdImage alloc] initWithURL:url scale:[UIScreen mainScreen].scale]);
            }
            return;
        }
        GADNativeAdImage *gadImage = [[GADNativeAdImage alloc] initWithImage:image];
        if (completion) {
            completion(gadImage);
        }
    }];
}
@end
