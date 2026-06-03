//
//  ALAdMasterNativeAd.m
//  Mediation/MAX
//

#import "ALAdMasterNativeAd.h"
#import <AdMasterSDK/AdMasterSDK.h>
#import <AppLovinSDK/AppLovinSDK.h>

@interface ALAdMasterNativeAd ()
@property (nonatomic, strong) ADMNativeAdObject *admNativeObject;
@property (nonatomic, strong, nullable) ADMNativeVideoView *admVideoView;
@property (nonatomic, weak, nullable) UIViewController *presentingViewController;
@end

@implementation ALAdMasterNativeAd

- (instancetype)initWithNativeAdObject:(ADMNativeAdObject *)nativeAdObject
                             videoView:(nullable ADMNativeVideoView *)videoView
              presentingViewController:(nullable UIViewController *)presentingViewController
                          builderBlock:(NS_NOESCAPE MANativeAdBuilderBlock)builderBlock {
    self = [super initWithFormat:MAAdFormat.native builderBlock:builderBlock];
    if (self) {
        _admNativeObject = nativeAdObject;
        _admVideoView = videoView;
        _presentingViewController = presentingViewController;
    }
    return self;
}

- (BOOL)prepareForInteractionClickableViews:(NSArray<UIView *> *)clickableViews withContainer:(UIView *)container {
    if (!self.admNativeObject) {
        return NO;
    }
    UIViewController *vc = self.presentingViewController ?: [ALUtils topViewControllerFromKeyWindow];
    UIView *mediaView = self.admVideoView ?: self.mediaView;
    if (!mediaView) {
        mediaView = [[UIView alloc] initWithFrame:CGRectZero];
    }
    [self.admNativeObject registerViewForInteraction:container
                                           mediaView:mediaView
                                      clickableViews:clickableViews
                                      viewController:vc];
    return YES;
}

@end
