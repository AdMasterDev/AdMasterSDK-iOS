//
//  ADMNativeVideoViewDelegate.h
//  AdMasterSDK
//
//  Created by Yang,Dingjia on 2020/5/19.
//  Copyright © 2020 AdMaster Inc. All rights reserved.
//

#ifndef ADMNativeVideoViewDelegate_h
#define ADMNativeVideoViewDelegate_h

@class ADMNativeVideoView;
@protocol ADMNativeVideoViewDelegate <NSObject>

@optional

/**
 * Video is about to start playing.
 *
 * @param videoView self
 */
- (void)nativeVideoAdDidStartPlaying:(ADMNativeVideoView *)videoView;

/**
 * Video paused.
 *
 * @param videoView self
 */
- (void)nativeVideoAdDidPause:(ADMNativeVideoView *)videoView;

/**
 * Video replayed.
 *
 * @param videoView self
 */
- (void)nativeVideoAdDidReplay:(ADMNativeVideoView *)videoView;

/**
 * Playback completed.
 *
 * @param videoView self
 */
- (void)nativeVideoAdDidComplete:(ADMNativeVideoView *)videoView;

/**
 * Playback failed.
 *
 * @param videoView self
 */
- (void)nativeVideoAdDidFailed:(ADMNativeVideoView *)videoView;

/**
 * First frame rendered.
 *
 * @param videoView self
 */
- (void)nativeVideoAdDidReadyForDisplay:(ADMNativeVideoView *)videoView;

@end

#endif /* ADMNativeVideoViewDelegate_h */
