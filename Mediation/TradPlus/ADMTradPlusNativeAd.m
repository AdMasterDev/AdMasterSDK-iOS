//
//  ADMTradPlusNativeAd.m
//  TradPlusMediationAdMaster
//

#import "ADMTradPlusNativeAd.h"
#import "ADMTradPlusNativeAdapter.h"
#import "ADMTradPlusUtils.h"

@interface ADMTradPlusNativeAdapter (ADMTradPlusInternalCallbacks)
- (void)notifyNativeAdDidShow:(ADMTradPlusNativeAd *)nativeAd;
- (void)notifyNativeAdDidClick:(ADMTradPlusNativeAd *)nativeAd;
- (void)notifyNativeAdDidClose:(ADMTradPlusNativeAd *)nativeAd;
- (void)notifyNativeAdVideoDidStart:(ADMTradPlusNativeAd *)nativeAd;
- (void)notifyNativeAdVideoDidEnd:(ADMTradPlusNativeAd *)nativeAd;
@end

@interface ADMTradPlusNativeAd ()

@property (nonatomic, strong, readwrite) ADMNativeAdObject *nativeAdObject;
@property (nonatomic, weak, readwrite, nullable) ADMTradPlusNativeAdapter *adapter;
@property (nonatomic, copy, nullable) NSDictionary *serverExtra;
@property (nonatomic, copy, nullable) NSDictionary *localExtra;
@property (nonatomic, strong, readwrite, nullable) UIView *mediaView;
@property (nonatomic, strong, nullable) ADMNativeVideoView *admVideoView;
@property (nonatomic, weak, readwrite, nullable) UIView *registeredContainerView;
@property (nonatomic, copy, nullable) NSArray<UIView *> *registeredClickableViews;
@property (nonatomic, weak, nullable) UIViewController *registeredViewController;
@property (nonatomic, assign) BOOL hasRecordedImpression;

@end

@implementation ADMTradPlusNativeAd

- (instancetype)initWithNativeAdObject:(ADMNativeAdObject *)nativeAdObject
                               adapter:(ADMTradPlusNativeAdapter *)adapter
                           serverExtra:(NSDictionary *)serverExtra
                            localExtra:(NSDictionary *)localExtra {
    self = [super init];
    if (self) {
        _nativeAdObject = nativeAdObject;
        _adapter = adapter;
        _serverExtra = [serverExtra copy];
        _localExtra = [localExtra copy];
        _nativeAdObject.interactionDelegate = self;
        [self setupMediaViewIfNeeded];
    }
    return self;
}

- (void)setupMediaViewIfNeeded {
    if ([self isVideoAd]) {
        CGSize size = [ADMTradPlusUtils adSizeFromServerExtra:self.serverExtra
                                                   localExtra:self.localExtra
                                                  defaultSize:CGSizeMake(320.0, 180.0)];
        ADMNativeVideoView *videoView = [[ADMNativeVideoView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)
                                                                        andObject:self.nativeAdObject];
        videoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        videoView.clipsToBounds = YES;
        videoView.videoDelegate = self;
        self.admVideoView = videoView;
        self.mediaView = videoView;
    }
}

#pragma mark - Accessors

- (NSString *)title {
    return self.nativeAdObject.title;
}

- (NSString *)mainText {
    return self.nativeAdObject.text;
}

- (NSString *)ctaText {
    return self.nativeAdObject.actButtonString;
}

- (NSString *)advertiserName {
    return self.nativeAdObject.brandName;
}

- (NSString *)iconImageURLString {
    return self.nativeAdObject.iconImageURLString;
}

- (NSString *)mainImageURLString {
    return self.nativeAdObject.mainImageURLString;
}

- (NSArray<NSString *> *)imageURLList {
    if (self.nativeAdObject.morepics.count > 0) {
        return self.nativeAdObject.morepics;
    }
    if (self.nativeAdObject.mainImageURLString.length > 0) {
        return @[self.nativeAdObject.mainImageURLString];
    }
    return @[];
}

- (NSString *)videoURLString {
    return self.nativeAdObject.videoURLString;
}

- (NSTimeInterval)videoDuration {
    return self.nativeAdObject.videoDuration ? [self.nativeAdObject.videoDuration doubleValue] : 0.0;
}

- (CGFloat)mainImageWidth {
    return self.nativeAdObject.w > 0 ? (CGFloat)self.nativeAdObject.w : 0.0;
}

- (CGFloat)mainImageHeight {
    return self.nativeAdObject.h > 0 ? (CGFloat)self.nativeAdObject.h : 0.0;
}

- (CGFloat)aspectRatio {
    if (self.nativeAdObject.aspectRatio > 0) {
        return (CGFloat)self.nativeAdObject.aspectRatio;
    }
    CGFloat w = [self mainImageWidth];
    CGFloat h = [self mainImageHeight];
    return (w > 0 && h > 0) ? (w / h) : (16.0 / 9.0);
}

- (BOOL)isVideoAd {
    return self.nativeAdObject.materialType == VIDEO;
}

- (BOOL)isExpressAd {
    return self.nativeAdObject.materialType == HTML;
}

- (double)ecpmCents {
    return [ADMTradPlusUtils parseECPMCentsFromString:[self.nativeAdObject getECPMLevel]];
}

#pragma mark - Interaction Registration

- (void)registerContainer:(UIView *)containerView
       withClickableViews:(NSArray<UIView *> *)clickableViews
           viewController:(UIViewController *)viewController {
    if (!containerView) {
        return;
    }
    self.registeredContainerView = containerView;
    self.registeredClickableViews = clickableViews;
    self.registeredViewController = viewController;
    [ADMTradPlusUtils dispatchOnMainThread:^{
        UIViewController *vc = [ADMTradPlusUtils topMostViewControllerFrom:viewController];
        if (vc) {
            self.registeredViewController = vc;
            [self.nativeAdObject setPresentAdViewController:vc];
        }
        [self.nativeAdObject registerViewForInteraction:containerView
                                              mediaView:self.mediaView
                                         clickableViews:clickableViews
                                         viewController:vc];
        if (self.admVideoView) {
            if (self.admVideoView.superview &&
                CGRectGetWidth(self.admVideoView.superview.bounds) > 0 &&
                CGRectGetHeight(self.admVideoView.superview.bounds) > 0) {
                self.admVideoView.frame = self.admVideoView.superview.bounds;
            }
            [self.admVideoView render];
            [self.admVideoView reSize];
            [self.admVideoView play];
        }
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.08 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf && strongSelf.registeredContainerView.window != nil) {
                [strongSelf activateMediaAndImpressionIfNeeded];
            }
        });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf && strongSelf.registeredContainerView.window != nil) {
                [strongSelf activateMediaAndImpressionIfNeeded];
            }
        });
    }];
}

- (void)activateMediaAndImpressionIfNeeded {
    [ADMTradPlusUtils dispatchOnMainThread:^{
        UIView *containerView = self.registeredContainerView;
        if (!containerView) {
            return;
        }
        if (containerView.superview) {
            [containerView.superview setNeedsLayout];
            [containerView.superview layoutIfNeeded];
        }
        [containerView setNeedsLayout];
        [containerView layoutIfNeeded];

        if (self.mediaView.superview) {
            [self.mediaView.superview setNeedsLayout];
            [self.mediaView.superview layoutIfNeeded];
            CGRect parentBounds = self.mediaView.superview.bounds;
            if (CGRectGetWidth(parentBounds) > 0 && CGRectGetHeight(parentBounds) > 0) {
                self.mediaView.frame = parentBounds;
                self.mediaView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            }
        }

        UIViewController *vc = [ADMTradPlusUtils topMostViewControllerFrom:self.registeredViewController];
        if (vc) {
            self.registeredViewController = vc;
            [self.nativeAdObject setPresentAdViewController:vc];
        }
        [self.nativeAdObject registerViewForInteraction:containerView
                                              mediaView:self.mediaView
                                         clickableViews:self.registeredClickableViews
                                         viewController:vc];
        if (self.admVideoView) {
            [self.admVideoView render];
            [self.admVideoView reSize];
            [self.admVideoView play];
        }
    }];
}

- (void)unregisterView {
    [ADMTradPlusUtils dispatchOnMainThread:^{
        if (self.registeredContainerView) {
            [self.nativeAdObject unregisterView:self.registeredContainerView];
            self.registeredContainerView = nil;
        }
    }];
}

- (NSDictionary *)toTradPlusAssetDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"nativeAd"] = self;
    dict[@"nativeAdObject"] = self.nativeAdObject;
    if (self.title) {
        dict[@"title"] = self.title;
    }
    if (self.mainText) {
        dict[@"text"] = self.mainText;
    }
    if (self.ctaText) {
        dict[@"cta"] = self.ctaText;
    }
    if (self.advertiserName) {
        dict[@"advertiser"] = self.advertiserName;
    }
    if (self.iconImageURLString) {
        dict[@"icon_url"] = self.iconImageURLString;
    }
    if (self.mainImageURLString) {
        dict[@"image_url"] = self.mainImageURLString;
    }
    if (self.imageURLList.count > 0) {
        dict[@"image_list"] = self.imageURLList;
    }
    if (self.videoURLString) {
        dict[@"video_url"] = self.videoURLString;
    }
    dict[@"video_duration"] = @([self videoDuration]);
    dict[@"is_video"] = @([self isVideoAd]);
    dict[@"is_express"] = @([self isExpressAd]);
    dict[@"ecpm_cents"] = @([self ecpmCents]);
    if (self.mediaView) {
        dict[@"media_view"] = self.mediaView;
    }
    return [dict copy];
}

- (void)destroy {
    [ADMTradPlusUtils dispatchOnMainThread:^{
        if (self.registeredContainerView) {
            [self.nativeAdObject unregisterView:self.registeredContainerView];
            self.registeredContainerView = nil;
        }
        if (self.admVideoView) {
            [self.admVideoView stop];
            self.admVideoView.videoDelegate = nil;
            [self.admVideoView removeFromSuperview];
            self.admVideoView = nil;
        }
        self.mediaView = nil;
        self.nativeAdObject.interactionDelegate = nil;
    }];
}

#pragma mark - ADMNativeInteractionDelegate

- (void)handleNativeImpression {
    if (self.hasRecordedImpression) {
        return;
    }
    self.hasRecordedImpression = YES;
    [self.adapter notifyNativeAdDidShow:self];
}

- (void)nativeAd:(ADMNativeAdObject *)ad didRecordImpressionForView:(UIView *)view {
    [self handleNativeImpression];
}

- (void)nativeAd:(ADMNativeAdObject *)ad didRecordClickForView:(UIView *)view {
    [self.adapter notifyNativeAdDidClick:self];
}

- (void)nativeAd:(ADMNativeAdObject *)ad didDismissLandingPageFromView:(UIView *)view {
}

- (void)nativeAd:(ADMNativeAdObject *)ad didDismissDislikeWithReasonCode:(NSInteger)reasonCode {
    [self.adapter notifyNativeAdDidClose:self];
}

- (void)nativeAdWillExpose:(ADMNativeAdObject *)nativeAdObject {
    [self handleNativeImpression];
}

- (void)nativeAdDidRecordImpression:(ADMNativeAdObject *)nativeAdObject {
    [self handleNativeImpression];
}

- (void)nativeAdDidClick:(ADMNativeAdObject *)nativeAdObject {
    [self.adapter notifyNativeAdDidClick:self];
}

- (void)nativeAdDidFinishHandlingClick:(ADMNativeAdObject *)nativeAdObject {
}

- (void)nativeAdApplicationWillEnterBackground:(ADMNativeAdObject *)nativeAdObject {
}

- (void)nativeAdDislikeClick:(ADMNativeAdObject *)nativeAdObject {
    [self.adapter notifyNativeAdDidClose:self];
}

#pragma mark - ADMNativeVideoViewDelegate

- (void)nativeVideoAdDidStartPlaying:(ADMNativeVideoView *)videoView {
    [self.adapter notifyNativeAdVideoDidStart:self];
}

- (void)nativeVideoAdDidPause:(ADMNativeVideoView *)videoView {
}

- (void)nativeVideoAdDidComplete:(ADMNativeVideoView *)videoView {
    [self.adapter notifyNativeAdVideoDidEnd:self];
}

- (void)nativeVideoAdDidFailWithError:(ADMNativeVideoView *)videoView {
}

- (void)nativeVideoAdDidReplay:(ADMNativeVideoView *)videoView {
}

@end
