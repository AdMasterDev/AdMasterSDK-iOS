#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AdMasterSDK/AdMasterSDK.h>
#import "ADMTopOnAnyThinkCompat.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * TopOn (AnyThink) 原生自渲染广告包装模型
 * 封装 ADMNativeAdObject 与 ADMNativeVideoView，统一映射图文/视频素材字段及曝光点击事件
 * 对标 Android: cc.admaster.android.topon.adapter.AdMasterTopOnNativeAd
 */
@interface ADMTopOnNativeAd : NSObject <ADMNativeInteractionDelegate, ADMNativeVideoViewDelegate>

/// 底层 AdMaster 原生广告数据对象
@property (nonatomic, strong, readonly) ADMNativeAdObject *nativeAdObject;

/// 事件回调代理
@property (nonatomic, weak, nullable) id <ADMTopOnAdapterEventDelegate> delegate;

/// 广告标题
@property (nonatomic, copy, readonly, nullable) NSString *title;

/// 广告描述正文
@property (nonatomic, copy, readonly, nullable) NSString *text;

/// 行动号召按钮文案（CTA）
@property (nonatomic, copy, readonly, nullable) NSString *ctaText;

/// 广告主/品牌名称（对应 brandName）
@property (nonatomic, copy, readonly, nullable) NSString *advertiser;

/// 图标 URL
@property (nonatomic, copy, readonly, nullable) NSString *iconUrl;

/// 主图 URL
@property (nonatomic, copy, readonly, nullable) NSString *imageUrl;

/// 多图 URL 列表（对应 morepics）
@property (nonatomic, copy, readonly, nullable) NSArray<NSString *> *imageList;

/// 视频 URL
@property (nonatomic, copy, readonly, nullable) NSString *videoUrl;

/// 视频时长（秒）
@property (nonatomic, assign, readonly) NSTimeInterval videoDuration;

/// 主图宽度
@property (nonatomic, assign, readonly) CGFloat mainImageWidth;

/// 主图高度
@property (nonatomic, assign, readonly) CGFloat mainImageHeight;

/// 主图宽高比
@property (nonatomic, assign, readonly) CGFloat aspectRatio;

/// 是否为视频类原生广告
@property (nonatomic, assign, readonly) BOOL isVideo;

/// 媒体视图（当 isVideo 时返回 ADMNativeVideoView，否则返回 nil）
@property (nonatomic, strong, readonly, nullable) UIView *mediaView;

- (instancetype)initWithNativeAdObject:(ADMNativeAdObject *)nativeAdObject;

/// 注册自渲染容器与可点击视图以开启曝光与点击追踪
- (void)registerClickableViews:(NSArray<UIView *> *)clickableViews
                   inContainer:(UIView *)container
                viewController:(nullable UIViewController *)viewController;

/// TopOn 风格别名：准备并注册自渲染容器与可点击视图
- (void)prepareWithContainer:(UIView *)container
              clickableViews:(NSArray<UIView *> *)clickableViews
              viewController:(nullable UIViewController *)viewController;

/// 解除视图绑定并停止视频播放
- (void)unregisterView;

/// 广告是否已过期
- (BOOL)isExpired;

@end

NS_ASSUME_NONNULL_END
