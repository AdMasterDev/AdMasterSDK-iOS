//
//  ADMCommonConfig.h
//  AdMasterSDK
//
//  Created by dengjinxiang on 13-8-22.
//
//
#import <UIKit/UIKit.h>
#ifndef ADM_CommonConfig_h
#define ADM_CommonConfig_h

typedef void (^ADMViewCompletionBlock)(NSArray *errors);

typedef enum {
    NORMAL, // Image or image+text ad
    VIDEO, // Video ad; app must provide a player
    HTML, // HTML template ad
    GIF // GIF ad
} ADMMaterialType;

typedef enum {
    ADMNativeAdActionTypeLP = 1,   // Landing page (in-app WebView)
    ADMNativeAdActionTypeDL = 2,   // App download ad
    ADMNativeAdActionTypeDeepLink = 512    // Deep link / app open ad
} ADMNativeAdActionType;

typedef enum {
    onShow,             // Video impression
    onClickToPlay,      // Tap to play
    onStart,            // Playback started
    onError,            // Playback failed
    onComplete,         // Playback completed
    onClose,            // Playback ended
    onFullScreen,       // Entered fullscreen
    onClick,            // Ad clicked
    onSkip,             // Video skipped
    onShowEndCard,      // End card shown
    onClickEndCard,     // End card clicked
    onClickDownloadDirect,  // Direct download from video ad
    onCacheSuccess,     // Video cached
    onCacheFail,        // Video cache failed
    onCacheExpire,      // Ad expired
    onReplay,           // Replay
    onPlayEnd,          // Playback stopped (portrait/landscape video)
    onMute,             // Mute toggled
    onReady,            // Ready to play
    onPlay,             // play() invoked
    onFrozen,           // Player stalled
    onVideoLoaded,      // Video ready to play (vload / 108-2)
    onVPlay25,          // 25% progress
    onVPlay50,          // 50% progress
    onVPlay75           // 75% progress
} ADMNativeVideoEvent;

/**
 * User gender
 */
typedef enum {
    ADMMale = 0,
    ADMFeMale = 1,
    ADMSexUnknown = 2,
} ADMUserGender;

/**
 * Landing page navigation bar style
 */
typedef enum {
    ADMLpStyleDefault,
    ADMLpStyleRed,
    ADMLpStyleGreen,
    ADMLpStyleBrown,
    ADMLpStyleDarkBlue,
    ADMLpStyleLightBlue,
    ADMLpStyleBlack
} ADMLpStyle;

/**
 * Dislike / feedback reason selected by the user
 */
typedef NS_ENUM(NSInteger, ADMDislikeReasonType) {
    ADMDislikeReasonCancel = -1, // User dismissed without selecting
    ADMDislikeReasonUnlike = 0, // Not interested
    ADMDislikeReasonLowQuality, // Low quality
    ADMDislikeReasonRepeatRecommend, // Repetitive
    ADMDislikeReasonVulgarPornography, // Adult content
    ADMDislikeReasonViolatingLaws, // Illegal content
    ADMDislikeReasonFake, // Misleading
    ADMDislikeReasonInducedClick, // Clickbait
    ADMDislikeReasonSuspectedPlagiarism // Suspected plagiarism
};

#endif

#define ADM_DEPRECATED_MSG(instead) DEPRECATED_MSG_ATTRIBUTE(instead)
#define ADM_DEPRECATED DEPRECATED_ATTRIBUTE
