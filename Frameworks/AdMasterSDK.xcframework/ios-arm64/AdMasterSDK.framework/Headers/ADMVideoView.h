//
//  ADMVideoView.h
//  AdMasterSDK
//
//  Created by Yang,Dingjia on 2018/11/13.
//  Copyright © 2018 AdMaster Inc. All rights reserved.
//

#ifndef ADMVideoView_h
#define ADMVideoView_h

#import <UIKit/UIKit.h>
#import <AdMasterSDK/ADMCommonConfig.h>
#import <AVFoundation/AVFoundation.h>

@class ADMVideoView;
@protocol ADMVideoViewDelegate <NSObject>
@optional

/**
 * Video is about to start playing.
 *
 * @param videoView self
 */
- (void)fullscreenVideoAdDidStartPlaying:(ADMVideoView *)videoView;

/**
 * Video paused.
 *
 * @param videoView self
 */
- (void)fullscreenVideoAdDidPause:(ADMVideoView *)videoView;

/**
 * Video replayed.
 *
 * @param videoView self
 */
- (void)fullscreenVideoAdDidReplay:(ADMVideoView *)videoView;

/**
 * Playback completed.
 *
 * @param videoView self
 */
- (void)fullscreenVideoAdDidComplete:(ADMVideoView *)videoView;

/**
 * Playback failed.
 *
 * @param videoView self
 */
- (void)fullscreenVideoAdDidFailed:(ADMVideoView *)videoView;

/**
 * Video clicked.
 *
 * @param videoView self
 */
- (void)fullscreenVideoAdDidClick:(ADMVideoView *)videoView;

@end

@interface ADMVideoView : UIView

@property (nonatomic, weak) id<ADMVideoViewDelegate> delegate;

/**
 * Creative material type.
 */
@property (nonatomic, assign) ADMMaterialType materialType;

/**
 * Designated initializer.
 *
 * @param frame View size
 * @param object ADMNativeAdObject
 * @return ADMVideoView instance
 */
- (instancetype)initWithFrame:(CGRect)frame andObject:(id)object;

/**
 * Set AVAudioSession category; call before play.
 */
- (void)setAudioSessionCategory:(AVAudioSessionCategory)category;

/**
 * Start playback.
 */
- (void)play;

/**
 * Replay from the beginning.
 */
- (void)replay;

/**
 * Pause playback.
 */
- (void)pause;

/**
 * Stop and tear down the player.
 */
- (void)stop;

/**
 * Hide the pause button (shown by default). Call before play.
 *
 * @param hidden YES to hide, NO to show
 */
- (void)hidePauseButton:(BOOL)hidden;

/**
 * Mute or unmute.
 *
 * @param mute YES muted, NO unmuted
 */
- (void)setVideoMute:(BOOL)mute;

/**
 * Whether playback is in progress.
 */
- (BOOL)isPlaying;

/**
 * Current playback time.
 */
- (NSTimeInterval)currentTime;

/**
 * Total video duration.
 */
- (NSTimeInterval)duration;

#pragma mark - Billing (important)

/**
 * Video click for click billing.
 */
- (void)handleClick;


@end

#endif /* ADMVideoView_h */
