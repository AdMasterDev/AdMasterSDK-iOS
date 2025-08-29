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

@interface ADMCustomEventNativeAd () <ADMNativeAdDelegate, ADMNativeVideoViewDelegate, ADMNativeInterationDelegate, GADMediationNativeAd> {
    __weak id<GADMediationNativeAdEventDelegate> _adEventDelegate;
    GADMediationNativeLoadCompletionHandler _loadCompletionHandler;
    GADNativeAdViewAdOptions *_nativeAdViewAdOptions;
    
    ADMNative *_nativeAd;
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
        [_nativeAdObject registerViewForInteraction:view mediaView:_nativeVideoView clickableViews:assets viewController:viewController];
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
    return NO;
}

- (BOOL)handlesUserImpressions {
    return NO;
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
    NSString *adUnitID = [ADMCustomEventUtils adUnitIDFromAdConfigurationParameter:parameter];
    if (!adUnitID) {
        NSError *error = [ADMCustomEventUtils errorWithCode:ADMCustomEventErrorInvalidAdUnitID
                                                description:@"Missing ad_unit_id in configuration"];
        _adEventDelegate = _loadCompletionHandler(nil, error);
        return;
    }
    
    _nativeAd = [[ADMNative alloc] init];
    _nativeAd.adUnitTag = adUnitID;
    _nativeAd.adDelegate = self;
    [_nativeAd load];
}

#pragma mark ADMNativeAdDelegate implementation

- (void)nativeAdObjectsSuccessLoad:(NSArray *)nativeAds nativeAd:(ADMNative *)nativeAd {
    if (!nativeAds || nativeAds.count == 0 || [nativeAds.firstObject isExpired]) {
        NSError *error = [ADMCustomEventUtils errorWithCode:ADMCustomEventErrorAdLoadFailed
                                                description:@"No valid native ad object received"];
        _adEventDelegate = _loadCompletionHandler(nil, error);
        return;
    }
    _nativeAdObject = nativeAds.firstObject;
    _nativeAdObject.interationDelegate = self;
    
    dispatch_group_t group = dispatch_group_create();
    __block GADNativeAdImage *loadedIcon = nil;
    __block GADNativeAdImage *loadedImage = nil;
    
    dispatch_group_enter(group);
    __weak typeof(self) weakSelf = self;
    [self loadImageFromURL:_nativeAdObject.iconImageURLString completion:^(GADNativeAdImage * _Nullable image) {
        loadedIcon = image;
        dispatch_group_leave(group);
    }];
    
    if (_nativeAdObject.materialType != VIDEO) {
        dispatch_group_enter(group);
        [weakSelf loadImageFromURL:_nativeAdObject.mainImageURLString completion:^(GADNativeAdImage * _Nullable image) {
            loadedImage = image;
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

- (void)nativeAdsFailLoadCode:(NSString *)errCode
                      message:(NSString *)message
                     nativeAd:(ADMNative *)nativeAd
                     adObject:(ADMNativeAdObject *)adObject {
    NSError *error = [ADMCustomEventUtils errorWithCode:ADMCustomEventErrorAdLoadFailed
                                            description:[NSString stringWithFormat:@"Ad load failure callback with error code: %@, message: %@", errCode, message]];
    _adEventDelegate = _loadCompletionHandler(nil, error);
}

#pragma mark - ADMNativeInterationDelegate implementation

- (void)nativeAdClicked:(UIView *)nativeAdView nativeAdDataObject:(ADMNativeAdObject *)object {
    [_adEventDelegate reportClick];
}

- (void)didDismissLandingPage:(UIView *)nativeAdView {
    [_adEventDelegate didDismissFullScreenView];
}

- (void)nativeAdExposure:(UIView *)nativeAdView nativeAdDataObject:(ADMNativeAdObject *)object {
    [_adEventDelegate reportImpression];
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

#pragma mark Load GADNativeAdImage

- (void)loadImageFromURL:(NSString *)urlString completion:(void(^)(GADNativeAdImage * _Nullable image))completion {
    if (urlString == nil) {
        if (completion) {
            completion(nil);
        }
        return;
    }
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        if (completion) {
            completion(nil);
        }
        return;
    }
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error || !data) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(nil);
                }
            });
            return;
        }
        UIImage *image = [UIImage imageWithData:data];
        if (!image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(nil);
                }
            });
            return;
        }
        GADNativeAdImage *gadImage = [[GADNativeAdImage alloc] initWithImage:image];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(gadImage);
            }
        });
    }];
    [task resume];
}
@end
