//
//  ADMVideoView.h
//  AdMasterSDK
//
//  Created by Yang,Dingjia on 2018/11/13.
//  Copyright © 2018 AdMaster Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AdMasterSDK/ADMCommonConfig.h>
#import <AVFoundation/AVFoundation.h>

@class ADMVideoView;
@protocol ADMVideoViewDelegate <NSObject>
@optional

/**
 视频准备开始播放
 
 @param videoView self
 */
- (void)fullscreenVideoAdDidStartPlaying:(ADMVideoView *)videoView;

/**
 视频暂停播放
 
 @param videoView self
 */
- (void)fullscreenVideoAdDidPause:(ADMVideoView *)videoView;

/**
 视频重播
 
 @param videoView self
 */
- (void)fullscreenVideoAdDidReplay:(ADMVideoView *)videoView;

/**
 视频播放完成

 @param videoView self
 */
- (void)fullscreenVideoAdDidComplete:(ADMVideoView *)videoView;

/**
 视频播放失败

 @param videoView self
 */
- (void)fullscreenVideoAdDidFailed:(ADMVideoView *)videoView;

/**
 视频发生点击
 
 @param videoView self
 */
- (void)fullscreenVideoAdDidClick:(ADMVideoView *)videoView;

@end

@interface ADMVideoView : UIView

@property (nonatomic, weak) id <ADMVideoViewDelegate> delegate;

/**
 * 广告素材type
 */
@property (nonatomic, assign) ADMMaterialType materialType;

/**
 初始化方法

 @param frame videoView尺寸
 @param object ADMNativeAdObject
 @return ADMVideoView
 */
- (instancetype)initWithFrame:(CGRect)frame andObject:(id)object;

/**
 设置AVAudioSessionCategory，play之前调用
 */
- (void)setAudioSessionCategory:(AVAudioSessionCategory)category;

/**
 开始播放
 */
- (void)play;

/**
 重新播放
 */
- (void)replay;

/**
 暂停播放
 */
- (void)pause;

/**
 销毁播放器
 */
- (void)stop;

/**
 设置隐藏暂停按钮，默认显示，请在play前调用
 
 @param hidden YES隐藏  NO显示
 */
- (void)hidePauseButton:(BOOL)hidden;

/**
 设置静音

 @param mute YES静音   NO非静音
 */
- (void)setVideoMute:(BOOL)mute;

/**
 是否播放中

 @return isPlaying
 */
- (BOOL)isPlaying;

/**
 当前播放时间

 @return 当前播放时间
 */
- (NSTimeInterval)currentTime;

/**
 视频总时长

 @return 视频总时长
 */
- (NSTimeInterval)duration;

#pragma mark - 计费相关视频事件 重要！

/**
 视频点击事件 点击计费接口
 */
- (void)handleClick;


@end
