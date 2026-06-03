//
//
//  Created by lishan04 on 15-11-1.
//  Copyright (c) 2015 lishan04. All rights reserved.
//

#ifndef ADMNativeVideoView_h
#define ADMNativeVideoView_h

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AdMasterSDK/ADMCommonConfig.h>
#import <AdMasterSDK/ADMNativeVideoViewDelegate.h>

@class ADMNativeAdObject;
@interface ADMNativeVideoView : UIView
@property BOOL supportControllerView;
@property BOOL supportActImage;

@property (nonatomic, weak) id<ADMNativeVideoViewDelegate> videoDelegate;

/**
 * Designated initializer.
 *
 * @param frame View size
 * @param object ADMNativeAdObject
 * @return ADMNativeVideoView instance
 */
- (instancetype)initWithFrame:(CGRect)frame andObject:(ADMNativeAdObject *)object;

/**
 * Set AVAudioSession category; call before play.
 */
- (void)setAudioSessionCategory:(AVAudioSessionCategory)category;

/**
 * Start playback (recommended when autoplay is off).
 */
- (void)play;

/**
 * Resume playback.
 */
- (void)resume;

/**
 * Pause playback.
 */
- (void)pause;

/**
 * Stop and tear down the player.
 */
- (void)stop;

/**
 * Replay from the beginning.
 */
- (void)replay;

/**
 * Whether playback is in progress.
 */
- (BOOL)isPlaying;

/**
 * Mute or unmute.
 *
 * @param mute YES muted, NO unmuted
 */
- (void)setVideoMute:(BOOL)mute;

/**
 * Update layout for a new frame.
 */
- (void)reSize;

/**
 * Trigger playback when Wi‑Fi autoplay is enabled. Call after scroll stops.
 * Since 5.351, optional: SDK auto-detects viewability for exposure-based play.
 */
- (BOOL)render;

@end

#endif /* ADMNativeVideoView_h */
