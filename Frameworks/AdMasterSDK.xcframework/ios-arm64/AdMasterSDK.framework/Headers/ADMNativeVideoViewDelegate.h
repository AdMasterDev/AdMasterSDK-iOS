//
//  ADMNativeVideoViewDelegate.h
//  AdMasterSDK
//
//  Created by Yang,Dingjia on 2020/5/19.
//  Copyright © 2020 AdMaster Inc. All rights reserved.
//

@class ADMNativeVideoView;
@protocol ADMNativeVideoViewDelegate <NSObject>

@optional

/**
 视频准备开始播放
 
 @param videoView self
 */
- (void)nativeVideoAdDidStartPlaying:(ADMNativeVideoView *)videoView;

/**
 视频暂停播放
 
 @param videoView self
 */
- (void)nativeVideoAdDidPause:(ADMNativeVideoView *)videoView;

/**
 视频重播
 
 @param videoView self
 */
- (void)nativeVideoAdDidReplay:(ADMNativeVideoView *)videoView;

/**
 视频播放完成

 @param videoView self
 */
- (void)nativeVideoAdDidComplete:(ADMNativeVideoView *)videoView;

/**
 视频播放失败

 @param videoView self
 */
- (void)nativeVideoAdDidFailed:(ADMNativeVideoView *)videoView;

/**
 视频首帧播放
 
 @param videoView self
 */
- (void)nativeVideoAdDidReadyForDisplay:(ADMNativeVideoView *)videoView;

@end
