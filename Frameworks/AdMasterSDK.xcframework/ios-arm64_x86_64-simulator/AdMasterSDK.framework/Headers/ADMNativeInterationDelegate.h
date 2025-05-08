//
//  ADMNativeInterationDelegate.h
//  AdMasterSDK
//
//  Created by yangdingjia on 2022/7/8.
//  Copyright © 2022 AdMaster Inc. All rights reserved.
//

#ifndef ADMNativeInterationDelegate_h
#define ADMNativeInterationDelegate_h


#endif /* ADMNativeInterationDelegate_h */

@class ADMNative;
@class ADMNativeAdObject;
@class ADMExpressNativeView;

@protocol ADMNativeInterationDelegate <NSObject>

@optional

/**
 *  广告曝光成功
 */
- (void)nativeAdExposure:(UIView *)nativeAdView nativeAdDataObject:(ADMNativeAdObject *)object;

/**
 *  广告曝光失败
 */
- (void)nativeAdExposureFail:(UIView *)nativeAdView
          nativeAdDataObject:(ADMNativeAdObject *)object
                  failReason:(int)reason;

/**
 *  广告点击
 */
- (void)nativeAdClicked:(UIView *)nativeAdView nativeAdDataObject:(ADMNativeAdObject *)object;

/**
 *  广告详情页关闭
 */
- (void)didDismissLandingPage:(UIView *)nativeAdView;

/**
 *  联盟官网点击跳转
 */
- (void)unionAdClicked:(UIView *)nativeAdView nativeAdDataObject:(ADMNativeAdObject *)object;

/**
 *  反馈弹窗展示
 *  @param adView 当前的广告视图
 */
- (void)nativeAdDislikeShow:(UIView *)adView;

/**
 *  反馈弹窗点击
 *  @param adView 当前的广告视图
 *  @param reason 反馈原因
 */
- (void)nativeAdDislikeClick:(UIView *)adView reason:(ADMDislikeReasonType)reason;

/**
 *  反馈弹窗关闭
 *  @param adView 当前的广告视图
 */
- (void)nativeAdDislikeClose:(UIView *)adView;

/**
 *  关闭按钮点击
 *  @param adView 当前的广告视图
 */
- (void)nativeAdCloseClick:(UIView *)adView;

/**
 *  视频缓存成功
 */
- (void)nativeVideoAdCacheSuccess:(ADMNative *)nativeAd;

/**
 *  视频缓存失败
 */
- (void)nativeVideoAdCacheFail:(ADMNative *)nativeAd withError:(ADMFailReason)reason;

/**
 * ADMExpressNativeView组件渲染成功
 */
- (void)nativeAdExpressSuccessRender:(ADMExpressNativeView *)express
                            nativeAd:(ADMNative *)nativeAd;

@end
