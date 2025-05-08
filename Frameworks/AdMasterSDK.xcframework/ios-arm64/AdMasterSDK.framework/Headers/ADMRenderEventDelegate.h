//
//  ADMRenderEventDelegate.h
//  AdMasterSDK
//
//  Created by lishan04 on 16/5/12.
//  Copyright © 2016年 AdMaster Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AdMasterSDK/ADMCommonConfig.h>
@class ADMAdRenderer;
@class ADMAdInstance;

@protocol ADMRenderEventDelegate <NSObject>
@optional
- (void)onAdLoaded:(ADMAdRenderer *)render
    withAdInstance:(ADMAdInstance *)adInstance
    withDictionary:(NSDictionary *)dict;

- (void)onAdError:(ADMAdRenderer *)render
   withAdInstance:(ADMAdInstance *)adInstance
           reason:(ADMFailReason)reason
   withDictionary:(NSDictionary *)dict;

- (void)onAdPresent:(ADMAdRenderer *)render
        withAdInstance:(ADMAdInstance *)adInstance
        withDictionary:(NSDictionary *)dict;

- (void)onAdImpression:(ADMAdRenderer *)render
        withAdInstance:(ADMAdInstance *)adInstance
        withDictionary:(NSDictionary *)dict;

- (void)onAdClicked:(ADMAdRenderer *)render
     withAdInstance:(ADMAdInstance *)adInstance
     withDictionary:(NSDictionary *)dict;

- (void)onAdStart:(ADMAdRenderer *)render
   withAdInstance:(ADMAdInstance *)adInstance
   withDictionary:(NSDictionary *)dict;

- (void)onAdFinish:(ADMAdRenderer *)render
    withAdInstance:(ADMAdInstance *)adInstance
    withDictionary:(NSDictionary *)dict;

- (void)onAdSkip:(ADMAdRenderer *)render
  withAdInstance:(ADMAdInstance *)adInstance
  withDictionary:(NSDictionary *)dict;

- (void)onSplashVideoReadyPlay:(ADMAdRenderer *)render
                       withDictionary:(NSDictionary *)dict;

- (void)setVisibility:(BOOL)visibility;
/**
 *  在用户点击完广告条出现全屏广告页面以后，用户关闭全屏广告时的回调
 */
- (void)onAdDismissLp;


/**
 广告展现失败

 @param render AdRender
 @param adInstance ADMAdInstance
 @param reason ADMFailReason
 @param dict parameter
 */
- (void)onAdFailedDisplayAd:(ADMAdRenderer *)render
                 adInstance:(ADMAdInstance *)adInstance
                     reason:(ADMFailReason)reason
                 dictionary:(NSDictionary *)dict;


@end
