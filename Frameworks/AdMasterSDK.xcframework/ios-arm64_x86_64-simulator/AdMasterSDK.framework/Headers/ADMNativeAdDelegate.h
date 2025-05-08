//
//  ADMNativeAdDelegate.h
//  AdMasterSDK
//
//  Created by deng jinxiang on 13-8-1.
//
//
#import <Foundation/Foundation.h>
#import <AdMasterSDK/ADMCommonConfig.h>

@class ADMNative;
@class ADMNativeAdView;
@class ADMNativeAdObject;
@class ADMExpressNativeView;

@protocol ADMNativeAdDelegate <NSObject>

@required

/**
 * 广告请求成功
 * 请求成功的数组，如果只成功返回一条原生广告，数组大小为1
 * 注意：如果是返回元素，nativeAds为ADMNativeAdObject数组。如果是优选模板，nativeAds为ADMExpressNativeView数组
 */
- (void)nativeAdObjectsSuccessLoad:(NSArray *)nativeAds nativeAd:(ADMNative *)nativeAd;

/**
 * 广告请求失败
 * adObject对象内仅有竞胜竞败能力，支持无广告返回时提供竞败信息上传
 */
- (void)nativeAdsFailLoadCode:(NSString *)errCode
                      message:(NSString *)message
                     nativeAd:(ADMNative *)nativeAd
                     adObject:(ADMNativeAdObject *)adObject;

@optional

/**
 * 模版高度，仅用于信息流模版广告
 */
- (NSNumber *)admAdsHeight;

/**
 * 模版宽度，仅用于信息流模版广告
 */
- (NSNumber *)admAdsWidth;

/**
 *  渠道ID
 */
- (NSString *)channelId;

/**
 *  启动位置信息
 */
- (BOOL)enableLocation;//如果enable，plist 需要增加NSLocationWhenInUseUsageDescription

@end

#pragma mark - 视频缓存delegate

@protocol ADMNativeCacheDelegate <NSObject>

@optional
/**
 *  视频缓存成功
 */
- (void)nativeVideoAdCacheSuccess:(ADMNative *)nativeAd;

/**
 *  视频缓存失败
 */
- (void)nativeVideoAdCacheFail:(ADMNative *)nativeAd withError:(ADMFailReason)reason;

@end
