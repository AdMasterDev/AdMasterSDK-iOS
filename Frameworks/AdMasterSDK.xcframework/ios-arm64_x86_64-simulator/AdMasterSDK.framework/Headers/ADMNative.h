//
//  ADMNative.h
//  AdMasterSDK
//
//  Created by lishan04 on 15-1-8.
//
//

#import <Foundation/Foundation.h>
#import <AdMasterSDK/ADMNativeAdDelegate.h>
#import <AdMasterSDK/ADMNativeInterationDelegate.h>

@class ADMNativeAdView;

@interface ADMNative : NSObject

/**
 *  应用的APPID
 */
@property(nonatomic, copy) NSString *publisherId;

/**
 *  设置/获取代码位(广告位)id
 */
@property (nonatomic, copy) NSString *adUnitTag;

/**
 * 广告请求 delegate
 */
@property (nonatomic, weak) id<ADMNativeAdDelegate> adDelegate;

/**
 * 针对视频缓存delegate
 * 适用于竖版视频，信息流视频不建议使用
 */
@property (nonatomic, weak) id<ADMNativeCacheDelegate> cacheDelegate;

/**
 * 模版高度，仅用于信息流模版广告
 */
@property (nonatomic, strong) NSNumber *admAdsHeight;

/**
 * 模版宽度，仅用于信息流模版广告
 */
@property (nonatomic, strong) NSNumber *admAdsWidth;

/**
 *  使用controller present 落地页
 */
@property (nonatomic, weak) UIViewController *presentAdViewController;

/**
 * 广告请求成功后是否缓存视频物料，YES:缓存 NO:不缓存。默认缓存
 */
@property (nonatomic, assign) BOOL isCacheVideo;

/**
 * 广告请求超时时间，默认30s，单位s
 */
@property (nonatomic, assign) NSTimeInterval timeout;

/**
 * 广告类型，请在request请求之前赋值
 */
@property (nonatomic, assign) ADMAdType adType;

/**
 * 设置底价过滤，支持客户端与服务端bidding配置
 * 仅支持整数值，单位：分
 */
@property (nonatomic, assign) int bidFloor;

/**
 *  请求信息流广告
 *  注意广告的展示存在有效期，单次检索后须在一定时间内展示在页面上
 */
- (void)load;


/**
 *  预加载视频素材  如果有多条素材会在所以素材均缓存完毕后回调nativeVideoAdCacheSuccess
 */
- (void)preloadVideoMaterial;

/**
 * 获取Bidding token
 * @return 媒体ADX请求广告所需的token
 */
- (NSString *)getBiddingToken;

/**
 * 请求bidding广告
 * @param bidId 媒体传入，竞价成功的广告id
 */
- (void)loadBiddingAd:(NSString *)bidId;

#pragma mark - DEPRECATED_ATTRIBUTE

- (void)setBiddingData:(NSString *)data ADM_DEPRECATED_MSG("已废弃，请接入最新的服务端bidding渲染方式");


@end
