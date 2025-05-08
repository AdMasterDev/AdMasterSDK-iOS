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
// SDK版本号
#define SDK_VERSION_IN_MSSP @"1.0.0"

typedef void (^ADMViewCompletionBlock)(NSArray *errors);

typedef enum {
    ADMAdTypeFeed = 0, // 默认 请求普通信息流广告
    ADMAdTypePortrait = 1,  // 竖版视频广告
    ADMAdTypeRewardVideo = 2,  // 激励视频
    ADMAdTypeExpressInterstitial = 4,   // 模板插屏
    ADMAdTypeSplash = 6 // 开屏
} ADMAdType;

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
