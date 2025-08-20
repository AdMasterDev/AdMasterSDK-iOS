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
    NORMAL, // 一般图文或图片广告
    VIDEO, // 视频广告，需开发者增加播放器支持
    HTML, // html模版广告
    GIF //GIF广告
} ADMMaterialType;

typedef enum {
    ADMNativeAdActionTypeLP = 1,   // 落地页广告
    ADMNativeAdActionTypeDL = 2,   // 下载类广告
    ADMNativeAdActionTypeDeepLink = 512    // 唤醒类广告
} ADMNativeAdActionType;

typedef enum {
    onShow,             // Video展现
    onClickToPlay,      // 点击播放
    onStart,            // 开始播放
    onError,            // 播放失败
    onComplete,         // 完整播放
    onClose,            // 播放结束
    onFullScreen,       // 全屏观看
    onClick,            // 广告点击
    onSkip,             // 跳过视频
    onShowEndCard,      // 展现endcard
    onClickEndCard,     // 点击endcard
    onClickDownloadDirect,  // 视频下载广告点击直接下载
    onCacheSuccess,     // 视频缓存成功
    onCacheFail,        // 视频缓存失败
    onCacheExpire,      // 广告过期
    onReplay,           // 重播
    onPlayEnd,          // 播放终止，横、竖版视频
    onMute,             // 静音按钮点击
    onReady,            // 准备播放
    onPlay,             // 调用播放
    onFrozen            // 播放器卡顿
} ADMNativeVideoEvent;

/**
 *  性别类型
 */
typedef enum {
    ADMMale = 0,
    ADMFeMale = 1,
    ADMSexUnknown = 2,
} ADMUserGender;

/**
 *  广告展示失败类型枚举
 */
typedef enum _ADMFailReason {
    ADMFailReason_NOAD = 0,// 没有推广返回
    ADMFailReason_EXCEPTION,//网络或其它异常
    ADMFailReason_FRAME//广告尺寸或元素异常，不显示广告
} ADMFailReason;


/**
 *  Landpage页面导航栏颜色设置
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
 * 用户选择的反馈原因
 */
typedef NS_ENUM(NSInteger, ADMDislikeReasonType) {
    ADMDislikeReasonCancel = -1, // 取消点击
    ADMDislikeReasonUnlike = 0, // 不感兴趣
    ADMDislikeReasonLowQuality, // 内容质量差
    ADMDislikeReasonRepeatRecommend, // 推荐重复
    ADMDislikeReasonVulgarPornography, // 低俗色情
    ADMDislikeReasonViolatingLaws, // 违法违规
    ADMDislikeReasonFake, // 虚假欺诈
    ADMDislikeReasonInducedClick, // 诱导点击
    ADMDislikeReasonSuspectedPlagiarism // 疑似抄袭
};

#endif

#define ADM_DEPRECATED_MSG(instead) DEPRECATED_MSG_ATTRIBUTE(instead)
#define ADM_DEPRECATED DEPRECATED_ATTRIBUTE
