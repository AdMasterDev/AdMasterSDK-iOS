#import "ADMTopOnNativeAd.h"
#import "ADMTopOnConstants.h"
#import "ADMTopOnUtils.h"

@interface ADMTopOnNativeAd ()

@property (nonatomic, strong) ADMNativeAdObject *nativeAdObject;
@property (nonatomic, strong, nullable) ADMNativeVideoView *videoView;
@property (nonatomic, weak, nullable) UIView *registeredContainer;

@end

@implementation ADMTopOnNativeAd

- (instancetype)initWithNativeAdObject:(ADMNativeAdObject *)nativeAdObject {
    self = [super init];
    if (self) {
        _nativeAdObject = nativeAdObject;
        _nativeAdObject.interactionDelegate = self;
    }
    return self;
}

#pragma mark - Material Properties

- (nullable NSString *)title {
    return self.nativeAdObject.title;
}

- (nullable NSString *)text {
    return self.nativeAdObject.text;
}

- (nullable NSString *)ctaText {
    return self.nativeAdObject.actButtonString;
}

- (nullable NSString *)advertiser {
    return self.nativeAdObject.brandName;
}

- (nullable NSString *)iconUrl {
    return self.nativeAdObject.iconImageURLString;
}

- (nullable NSString *)imageUrl {
    return self.nativeAdObject.mainImageURLString;
}

- (nullable NSArray<NSString *> *)imageList {
    return self.nativeAdObject.morepics;
}

- (nullable NSString *)videoUrl {
    return self.nativeAdObject.videoURLString;
}

- (NSTimeInterval)videoDuration {
    return [self.nativeAdObject.videoDuration doubleValue];
}

- (CGFloat)mainImageWidth {
    return (CGFloat)self.nativeAdObject.w;
}

- (CGFloat)mainImageHeight {
    return (CGFloat)self.nativeAdObject.h;
}

- (CGFloat)aspectRatio {
    if (self.nativeAdObject.aspectRatio > 0) {
        return (CGFloat)self.nativeAdObject.aspectRatio;
    }
    if (self.nativeAdObject.w > 0 && self.nativeAdObject.h > 0) {
        return (CGFloat)(self.nativeAdObject.w / self.nativeAdObject.h);
    }
    return 0.0;
}

- (BOOL)isVideo {
    return self.nativeAdObject.materialType == VIDEO;
}

- (nullable UIView *)mediaView {
    if (!self.isVideo) {
        return nil;
    }
    if (!self.videoView) {
        ADMNativeVideoView *vv = [[ADMNativeVideoView alloc] initWithFrame:CGRectMake(0, 0, 320, 180)
                                                                 andObject:self.nativeAdObject];
        vv.videoDelegate = self;
        self.videoView = vv;
    }
    return self.videoView;
}

#pragma mark - View Registration

static UIViewController *_Nullable ADMTopOnRootViewController(void) {
    UIWindow *keyWindow = nil;
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive &&
                [scene isKindOfClass:[UIWindowScene class]]) {
                for (UIWindow *window in ((UIWindowScene *)scene).windows) {
                    if (window.isKeyWindow) {
                        keyWindow = window;
                        break;
                    }
                }
                if (keyWindow) {
                    break;
                }
            }
        }
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (!keyWindow) {
        keyWindow = [UIApplication sharedApplication].keyWindow;
    }
#pragma clang diagnostic pop
    return keyWindow.rootViewController;
}

- (void)registerClickableViews:(NSArray<UIView *> *)clickableViews
                   inContainer:(UIView *)container
                viewController:(nullable UIViewController *)viewController {
    if (!container || !self.nativeAdObject) {
        return;
    }
    [ADMTopOnUtils dispatchOnMainThread:^{
        self.registeredContainer = container;
        self.nativeAdObject.interactionDelegate = self;
        if (viewController) {
            [self.nativeAdObject setPresentAdViewController:viewController];
        }

        UIView *media = nil;
        if (self.isVideo) {
            if (!self.videoView) {
                self.videoView = [[ADMNativeVideoView alloc] initWithFrame:container.bounds
                                                                 andObject:self.nativeAdObject];
                self.videoView.videoDelegate = self;
            }
            media = self.videoView;
        }
        if (!media) {
            media = [[UIView alloc] initWithFrame:CGRectZero];
        }

        UIViewController *presentingVC = viewController ?: ADMTopOnRootViewController();
        [self.nativeAdObject registerViewForInteraction:container
                                              mediaView:media
                                         clickableViews:clickableViews ?: @[]
                                         viewController:presentingVC];
        if (self.videoView) {
            [self.videoView render];
        }
    }];
}

- (void)prepareWithContainer:(UIView *)container
              clickableViews:(NSArray<UIView *> *)clickableViews
              viewController:(nullable UIViewController *)viewController {
    [self registerClickableViews:clickableViews inContainer:container viewController:viewController];
}

- (void)unregisterView {
    UIView *container = self.registeredContainer;
    self.registeredContainer = nil;
    ADMNativeVideoView *vv = self.videoView;
    self.videoView = nil;
    if (vv) {
        vv.videoDelegate = nil;
        [vv stop];
        [ADMTopOnUtils dispatchOnMainThread:^{
            [vv removeFromSuperview];
        }];
    }
    if (container && self.nativeAdObject) {
        [self.nativeAdObject unregisterView:container];
    }
}

- (BOOL)isExpired {
    return self.nativeAdObject ? [self.nativeAdObject isExpired] : YES;
}

#pragma mark - ADMNativeInteractionDelegate

- (void)nativeAd:(ADMNativeAdObject *)ad didRecordImpressionForView:(UIView *)view {
    [ADMTopOnUtils dispatchOnMainThread:^{
        if ([self.delegate respondsToSelector:@selector(topOnAdapterDidShow:extra:)]) {
            [self.delegate topOnAdapterDidShow:self extra:nil];
        }
    }];
}

- (void)nativeAd:(ADMNativeAdObject *)ad didFailToRecordImpressionForView:(UIView *)view error:(NSError *)error {
    [ADMTopOnUtils dispatchOnMainThread:^{
        NSError *mappedError = [ADMTopOnUtils errorFromADMError:(ADMError *)error
                                                    defaultCode:ADMTopOnErrorCodeAdPresentFailed
                                             defaultDescription:@"Native impression validation failed"];
        if ([self.delegate respondsToSelector:@selector(topOnAdapterDidFailToShow:error:)]) {
            [self.delegate topOnAdapterDidFailToShow:self error:mappedError];
        }
    }];
}

- (void)nativeAd:(ADMNativeAdObject *)ad didRecordClickForView:(UIView *)view {
    [ADMTopOnUtils dispatchOnMainThread:^{
        if ([self.delegate respondsToSelector:@selector(topOnAdapterDidClick:extra:)]) {
            [self.delegate topOnAdapterDidClick:self extra:nil];
        }
    }];
}

- (void)nativeAd:(ADMNativeAdObject *)ad didDismissLandingPageFromView:(UIView *)view {
}

- (void)nativeAd:(ADMNativeAdObject *)ad didDismissDislikeWithReasonCode:(NSInteger)reasonCode {
    [ADMTopOnUtils dispatchOnMainThread:^{
        if ([self.delegate respondsToSelector:@selector(topOnAdapterDidClose:extra:)]) {
            [self.delegate topOnAdapterDidClose:self extra:@{@"dislike_reason": @(reasonCode)}];
        }
    }];
}

#pragma mark - ADMNativeVideoViewDelegate

- (void)nativeVideoAdDidStartPlaying:(ADMNativeVideoView *)videoView {
    [ADMTopOnUtils dispatchOnMainThread:^{
        if ([self.delegate respondsToSelector:@selector(topOnAdapterVideoDidStart:extra:)]) {
            [self.delegate topOnAdapterVideoDidStart:self extra:nil];
        }
    }];
}

- (void)nativeVideoAdDidComplete:(ADMNativeVideoView *)videoView {
    [ADMTopOnUtils dispatchOnMainThread:^{
        if ([self.delegate respondsToSelector:@selector(topOnAdapterVideoDidEnd:extra:)]) {
            [self.delegate topOnAdapterVideoDidEnd:self extra:nil];
        }
    }];
}

- (void)nativeVideoAdDidFailed:(ADMNativeVideoView *)videoView {
    [ADMTopOnUtils dispatchOnMainThread:^{
        NSError *error = [ADMTopOnUtils errorWithCode:ADMTopOnErrorCodeAdPresentFailed
                                          description:@"Native video playback failed"];
        if ([self.delegate respondsToSelector:@selector(topOnAdapterDidFailToShow:error:)]) {
            [self.delegate topOnAdapterDidFailToShow:self error:error];
        }
    }];
}

@end
