//
//  ALAdMasterNativeAd.h
//  Mediation/MAX
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#if __has_include(<AppLovinSDK/AppLovinSDK.h>)
#import <AppLovinSDK/AppLovinSDK.h>
#endif

@class ADMNativeAdObject;
@class ADMNativeVideoView;

NS_ASSUME_NONNULL_BEGIN

@interface ALAdMasterNativeAd : MANativeAd

@property (nonatomic, strong, readonly) ADMNativeAdObject *admNativeObject;

- (instancetype)initWithNativeAdObject:(ADMNativeAdObject *)nativeAdObject
                             videoView:(nullable ADMNativeVideoView *)videoView
              presentingViewController:(nullable UIViewController *)presentingViewController
                          builderBlock:(NS_NOESCAPE MANativeAdBuilderBlock)builderBlock;

@end

NS_ASSUME_NONNULL_END
