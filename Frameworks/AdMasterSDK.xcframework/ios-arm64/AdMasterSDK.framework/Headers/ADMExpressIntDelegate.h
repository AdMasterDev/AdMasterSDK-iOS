//
//  ADMExpressIntDelegate.h
//  AdMasterSDK
//
//  Created by yangdingjia on 2021/9/18.
//  Copyright © 2021 AdMaster Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AdMasterSDK/ADMCommonConfig.h>

@class ADMExpressInterstitial;

@protocol ADMExpressIntDelegate <NSObject>

@required

/**
 * 广告请求成功
 */
- (void)interstitialAdLoaded:(ADMExpressInterstitial *)interstitial;

/**
 * 广告请求失败
 */
- (void)interstitialAdLoadFailCode:(NSString *)errCode
                           message:(NSString *)message
                    interstitialAd:(ADMExpressInterstitial *)interstitial;

@optional
#pragma mark - 广告请求delegate
/**
 *  广告曝光成功
 */
- (void)interstitialAdExposure:(ADMExpressInterstitial *)interstitial;

/**
 *  广告展现失败
 */
- (void)interstitialAdExposureFail:(ADMExpressInterstitial *)interstitial withError:(int)reason;


/**
 *  广告被关闭
 */
- (void)interstitialAdDidClose:(ADMExpressInterstitial *)interstitial;

/**
 *  广告被点击
 */
- (void)interstitialAdDidClick:(ADMExpressInterstitial *)interstitial;

/**
 *  广告落地页关闭
 */
- (void)interstitialAdDidLPClose:(ADMExpressInterstitial *)interstitial;

/**
 * 广告反馈点击
 */
- (void)interstitialAdDislikeClick:(ADMExpressInterstitial *)interstitial;

// 点击跳过
- (void)interstitialAdSkip:(ADMExpressInterstitial *)interstitial;

- (void)interstitialAdImpressed:(ADMExpressInterstitial *)interstitial;

- (void)interstitialAdEndCardShowed:(ADMExpressInterstitial *)interstitial;

#pragma mark - 视频缓存delegate

/**
 *  视频缓存成功
 */
- (void)interstitialAdDownloadSucceeded:(ADMExpressInterstitial *)interstitial;

/**
 *  视频缓存失败
 */
- (void)interstitialAdDownLoadFailed:(ADMExpressInterstitial *)interstitial;

/**
 *  视频播放失败
 */
- (void)interstitialAdVideoPlayFailed:(ADMExpressInterstitial *)interstitial WithError:(NSString *)error;
@end

