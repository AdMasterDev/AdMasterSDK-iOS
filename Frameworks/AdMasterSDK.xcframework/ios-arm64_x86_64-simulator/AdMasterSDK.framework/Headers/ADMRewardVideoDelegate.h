//
//  ADMRewardVideoDelegate.h
//  AdMasterSDK
//
//  Created by Yang,Dingjia on 2018/7/3.
//  Copyright © 2018年 AdMaster Inc. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <AdMasterSDK/ADMCommonConfig.h>

@class ADMRewardVideo;

@protocol ADMRewardVideoDelegate <NSObject>

@required

#pragma mark - 广告请求delegate
/**
 * 广告请求成功
 */
- (void)rewardedAdLoadSuccess:(ADMRewardVideo *)video;

/**
 * 广告请求失败
 */
- (void)rewardedAdLoadFailCode:(NSString *)errCode
                       message:(NSString *)message
                    rewardedAd:(ADMRewardVideo *)video;

@optional

#pragma mark - 视频缓存delegate
/**
 *  视频缓存成功
 */
- (void)rewardedVideoAdLoaded:(ADMRewardVideo *)video;

/**
 *  视频缓存失败
 */
- (void)rewardedVideoAdLoadFailed:(ADMRewardVideo *)video withError:(ADMFailReason)reason;

#pragma mark - 视频播放delegate

/**
 *  视频开始播放
 */
- (void)rewardedVideoAdDidStarted:(ADMRewardVideo *)video;

/**
 *  广告曝光成功
 */
- (void)rewardedVideoAdDidExposured:(ADMRewardVideo *)video;

/**
 *  广告展示失败
 */
- (void)rewardedVideoAdShowFailed:(ADMRewardVideo *)video withError:(ADMFailReason)reason;

/**
 *  广告完成播放
 */
- (void)rewardedVideoAdDidPlayFinish:(ADMRewardVideo *)video;

/**
 *  用户点击跳过
 @param progress 当前播放进度 单位百分比 （注意浮点数）
 */
- (void)rewardedVideoAdDidSkip:(ADMRewardVideo *)video withPlayingProgress:(CGFloat)progress;

/**
 *  用户点击关闭，激励视频视图关闭
 @param progress 当前播放进度 单位百分比 （注意浮点数）
 */
- (void)rewardedVideoAdDidClose:(ADMRewardVideo *)video withPlayingProgress:(CGFloat)progress;


/**
 *  用户点击关闭，激励视频视图即将关闭
 @param progress 当前播放进度 单位百分比 （注意浮点数）
 */
- (void)rewardedVideoAdWillClose:(ADMRewardVideo *)video withPlayingProgress:(CGFloat)progress;

/**
 *  用户点击广告
 @param progress 当前播放进度 单位百分比
 */
- (void)rewardedVideoAdDidClick:(ADMRewardVideo *)video withPlayingProgress:(CGFloat)progress;

/**
 *  Endcard展示
 */
- (void)rewardedVideoAdEndCardShow:(ADMRewardVideo *)video;

/**
 *  视频播放失败
 */
- (void)rewardedVideoAdPlayFailed:(ADMRewardVideo *)video withError:(NSString *)error;
@end

