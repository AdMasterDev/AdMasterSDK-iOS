//
//  ALAdMasterNativeAd.h
//  Mediation/MAX
//

#import <AppLovinSDK/AppLovinSDK.h>

@class ADMNativeAdObject;
@class ADMNativeVideoView;

NS_ASSUME_NONNULL_BEGIN

@interface ALAdMasterNativeAd : MANativeAd

- (instancetype)initWithNativeAdObject:(ADMNativeAdObject *)nativeAdObject
                             videoView:(nullable ADMNativeVideoView *)videoView
              presentingViewController:(nullable UIViewController *)presentingViewController
                          builderBlock:(NS_NOESCAPE MANativeAdBuilderBlock)builderBlock;

@end

NS_ASSUME_NONNULL_END
