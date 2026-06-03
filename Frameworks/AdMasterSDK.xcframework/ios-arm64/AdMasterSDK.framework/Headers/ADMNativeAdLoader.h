//
//  ADMNativeAdLoader.h
//  AdMasterSDK
//

#ifndef ADMNativeAdLoader_h
#define ADMNativeAdLoader_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AdMasterSDK/ADMRequest.h>
#import <AdMasterSDK/ADMError.h>

NS_ASSUME_NONNULL_BEGIN

@class ADMNativeAdLoader;
@class ADMNativeAdObject;

/// All delegate callbacks are invoked on the main thread.
@protocol ADMNativeAdLoaderDelegate <NSObject>

@optional

- (void)nativeAdLoader:(ADMNativeAdLoader *)loader didReceiveNativeAds:(NSArray<ADMNativeAdObject *> *)ads;
- (void)nativeAdLoader:(ADMNativeAdLoader *)loader didFailToReceiveAdWithError:(NSError *)error nativeAdObject:(nullable ADMNativeAdObject *)adObject;

- (void)nativeAd:(ADMNativeAdObject *)ad didRecordImpressionForView:(UIView *)view;
- (void)nativeAd:(ADMNativeAdObject *)ad didFailToRecordImpressionForView:(UIView *)view error:(NSError *)error;
- (void)nativeAd:(ADMNativeAdObject *)ad didRecordClickForView:(UIView *)view;
- (void)nativeAd:(ADMNativeAdObject *)ad didDismissLandingPageFromView:(UIView *)view;


/// Fired when the user submits a dislike / negative feedback reason.
- (void)nativeAd:(ADMNativeAdObject *)ad didDismissDislikeWithReasonCode:(NSInteger)reasonCode;

@end

@interface ADMNativeAdLoader : NSObject

@property (nonatomic, weak, nullable) id<ADMNativeAdLoaderDelegate> delegate;
@property (nonatomic, copy) ADMRequest *request;
@property (nonatomic, copy, readonly) NSString *publisherId;
@property (nonatomic, copy) NSString *adUnitTag;
@property (nonatomic, strong, nullable) NSNumber *templateWidth;
@property (nonatomic, strong, nullable) NSNumber *templateHeight;
@property (nonatomic, weak, nullable) UIViewController *presentAdViewController;
@property (nonatomic, assign) BOOL cachesVideoAssets;

- (void)load;
- (void)preloadVideoAssets;
- (nullable NSString *)getBiddingToken;
- (void)loadBiddingAdWithTokenId:(NSString *)tokenId;
- (void)loadBiddingAdWithADMData:(NSString *)admData;

@end

NS_ASSUME_NONNULL_END

#endif /* ADMNativeAdLoader_h */
