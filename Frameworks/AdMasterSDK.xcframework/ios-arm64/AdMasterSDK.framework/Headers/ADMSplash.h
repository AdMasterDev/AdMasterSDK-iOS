//
//  ADMSplash.h
//  AdMasterSDK
//
//  Created by LiYan on 16/5/25.
//  Copyright © 2016年 AdMaster Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AdMasterSDK/ADMSplashDelegate.h>
@interface ADMSplash : NSObject

/**
 *  委托对象
 */
@property (nonatomic, weak) id <ADMSplashDelegate> delegate;

/**
 * 开屏点睛-卡片样式delegate
 */
@property (nonatomic, weak) id <ADMSplashCardViewDelegate> cardDelegate;

/**
 * 开屏点睛-icon样式delegate
 */
@property (nonatomic, weak) id <ADMSplashFocusZoomOutViewDelegate> zoomOutDelegate;

/**
 * 是否支持开屏点睛-卡片样式
 * 广告返回后获取，不可set
 */
@property (nonatomic, assign, readonly) BOOL hasCardView;

/**
 * 是否支持开屏点睛-icon样式
 * 广告返回后获取，不可set
 */
@property (nonatomic, assign, readonly) BOOL hasZoomOutView;

/**
 *  应用的APPID
 */
@property(nonatomic, copy) NSString *publisherId;

/**
 *  设置/获取代码位id
 */
@property (nonatomic, copy) NSString *adUnitTag;

/**
 *  设置开屏广告是否可以点击的属性,开屏默认可以点击。
 */
@property (nonatomic, assign) BOOL canSplashClick;

/**
 *  SDK版本
 */
@property (nonatomic, readonly) NSString *version;

/**
 * 广告请求超时时间，默认3s，单位s
 */
@property (nonatomic, assign) NSTimeInterval timeout;

/**
 * 广告渲染视图大小，必须大于200*200
 */
@property (nonatomic, assign) CGSize adSize;

/**
 *  使用controller present 落地页
 */
@property (nonatomic, weak) UIViewController *presentAdViewController;

/**
 * 设置底价过滤，支持客户端与服务端bidding配置
 * 仅支持整数值，单位：分
 */
@property (nonatomic, assign) int bidFloor;

/**
 *  请求并展示半屏开屏广告，广告尺寸以传入view大小为准
 */
- (void)loadAndDisplayUsingContainerView:(UIView *)view;

/**
 * 请求开屏广告，仅请求不做展示，需要手动调用show展示广告
 * load之前请先设置开屏渲染视图大小：adSize
 */
- (void)load;

/**
 * 展示广告
*/
- (void)showInContainerView:(UIView *)view;

/**
 * 销毁开屏，释放资源
 */
- (void)stop;

/**
 * 广告是否可用
 * 缓存成功&广告未过期
 */
- (BOOL)isReady;

/**
 * 重置广告容器大小
*/
- (void)resizeLayout;

/**
 * 开屏广告自定义相关配置字段
 */
- (NSString *)getExtData;

/**
 *  广告价格标签
 */
- (NSString *)getECPMLevel;

- (NSString *)getPECPM;

/**
 * 竞价成功，上报竞价失败排名第二的信息
 * @param secondInfo 竞败方，排名第二的信息
 *        Key：ecpm Value：为本次竞败方排名第二的价格（单位：分），类型为Integer。选填
 *        Key：adn    Value：为本次竞败方排名第二的渠道ID，类型为Integer。具体ID枚举见文档
 * @param completion 发送成功或失败回调
 */
- (void)biddingSuccessWithSecondInfo:(NSDictionary *)secondInfo completion:(void (^)(BOOL success, NSString *errorInfo))completion;

/**
 * 反馈竞价失败及原因，无广告返回时也可用此接口上报竞胜方信息
 * @param winInfo 竞胜方的信息
 *        Key：ecpm Value：为本次竞胜方出价（单位：分），类型为Integer。选填
 *        Key：adn    Value：为本次竞胜方渠道ID，类型为Integer。具体ID枚举见文档
 * @param completion 发送成功或失败回调
 */
- (void)biddingFailWithWinInfo:(NSDictionary *)winInfo completion:(void (^)(BOOL success, NSString *errorInfo))completion;

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

/**
 * 根据key获取广告相关字段
 * @param key 需要获取的key字段
 * @return 字段的字符串
 */
- (NSString *)getAdDataForKey:(NSString *)key;

@end
