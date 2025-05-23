//
//
//  Created by lishan04 on 15-11-1.
//  Copyright (c) 2015 lishan04. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AdMasterSDK/ADMCommonConfig.h>
#import <AdMasterSDK/ADMNativeVideoViewDelegate.h>

@class ADMNativeAdObject;
@interface ADMNativeVideoView : UIView
@property BOOL supportControllerView;
@property BOOL supportActImage;

@property (nonatomic, weak) id <ADMNativeVideoViewDelegate> videoDelegate; //视频事件delegate

/**
 初始化方法

 @param frame videoView尺寸
 @param object ADMNativeAdObject
 @return ADMVideoView
 */
- (instancetype)initWithFrame:(CGRect)frame andObject:(ADMNativeAdObject *)object;

/**
 设置AVAudioSessionCategory，play之前调用
 */
- (void)setAudioSessionCategory:(AVAudioSessionCategory)category;

/**
 开始播放
 重要：建议广告非自动播放时调用
 */
- (void)play;

/**
 继续播放
 */
- (void)resume;

/**
 暂停播放
 */
- (void)pause;

/**
 销毁播放器
 */
- (void)stop;

/**
 重新播放
 */
- (void)replay;

/**
 是否播放中

 @return isPlaying
 */
- (BOOL)isPlaying;

/**
 设置静音

 @param mute YES静音   NO非静音
 */
- (void)setVideoMute:(BOOL)mute;

/**
 刷新视图frame
 */
- (void)reSize;

/**
 触发播放，仅设置wifi自动播放后生效。建议屏幕滑动停止后调用
 重要：5.351版本后，该接口可不调用，SDK内对视频曝光自检测
*/
- (BOOL)render;

@end
