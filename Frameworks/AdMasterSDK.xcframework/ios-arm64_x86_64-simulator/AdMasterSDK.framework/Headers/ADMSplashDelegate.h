//
//  ADMSplashDelegate.h
//  AdMasterSDK
//
//  Created by LiYan on 16/5/25.
//  Copyright © 2016年 AdMaster Inc. All rights reserved.
//

#import <AdMasterSDK/ADMCommonConfig.h>
#import <Foundation/Foundation.h>

@class ADMSplash;

@protocol ADMSplashDelegate <NSObject>

@required

/**
 * 开屏广告请求失败
 *
 * @param errCode 错误码
 * @param message 错误信息
 * @param splashAd 开屏广告对象
 */
- (void)splashAdLoadFailCode:(NSString *)errCode
                     message:(NSString *)message
                    splashAd:(ADMSplash *)splashAd;

@optional

/**
 *  渠道id
 */
- (NSString *)channelId;

/**
 *  启动位置信息
 */
- (BOOL)enableLocation;

/**
 *  广告曝光成功
 */
- (void)splashDidExposure:(ADMSplash *)splash;

/**
 *  广告展示成功
 */
- (void)splashSuccessPresentScreen:(ADMSplash *)splash;

/**
 *  广告展示失败
 */
- (void)splashlFailPresentScreen:(ADMSplash *)splash withError:(ADMFailReason) reason;

/**
 *  广告被点击
 */
- (void)splashDidClicked:(ADMSplash *)splash;

/**
 *  广告点击跳过
 */
- (void)splashSkipClick:(ADMSplash *)splash;

/**
 *  广告展示结束
 */
- (void)splashDidDismissScreen:(ADMSplash *)splash;

/**
 *  广告详情页消失
 */
- (void)splashDidDismissLp:(ADMSplash *)splash;

/**
 *  广告加载完成
 *  adType:广告类型 ADMMaterialType
 *  videoDuration:视频时长，仅广告为视频时出现。非视频类广告默认0。 单位ms
 */
- (void)splashDidReady:(ADMSplash *)splash
             AndAdType:(NSString *)adType
         VideoDuration:(NSInteger)videoDuration;

/**
 * 开屏广告请求成功
 *
 * @param splash 开屏广告对象
 */
- (void)splashAdLoadSuccess:(ADMSplash *)splash;

/**
 * 开屏广告缓存成功
 */
- (void)splashAdCacheSuccess:(ADMSplash *)splash;

/**
 * 开屏广告缓存失败
 */
- (void)splashAdCacheFail:(ADMSplash *)splash;


@end

@protocol ADMSplashCardViewDelegate <NSObject>

- (void)splashCardViewDidExposure:(ADMSplash *)splash;

- (void)splashCardViewDidClicked:(ADMSplash *)splash;

- (void)splashCardViewDidClose:(ADMSplash *)splash;

@end

@protocol ADMSplashFocusZoomOutViewDelegate <NSObject>

- (void)splashFocusZoomOutViewDidExposure:(ADMSplash *)splash;

- (void)splashFocusZoomOutViewDidClicked:(ADMSplash *)splash;

- (void)splashFocusZoomOutViewDidClose:(ADMSplash *)splash;

@end

