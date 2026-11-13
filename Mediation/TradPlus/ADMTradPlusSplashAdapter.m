//
//  ADMTradPlusSplashAdapter.m
//  TradPlusMediationAdMaster
//

#import "ADMTradPlusSplashAdapter.h"
#import "ADMTradPlusConstants.h"
#import "ADMTradPlusSDKInitManager.h"
#import "ADMTradPlusUtils.h"

@interface ADMTradPlusSplashAdapter ()

@property (nonatomic, strong, readwrite, nullable) ADMSplashAd *splashAd;
@property (nonatomic, strong, readwrite, nullable) UIView *internalContainerView;
@property (nonatomic, strong, readwrite, nullable) ADMTradPlusBiddingNotice *biddingNotice;
@property (nonatomic, copy, readwrite, nullable) NSDictionary *serverExtra;
@property (nonatomic, copy, readwrite, nullable) NSDictionary *localExtra;
@property (nonatomic, copy, nullable) TPAdLoadCompletionBlock loadCompletion;
@property (nonatomic, copy, nullable) TPBiddingCompletionBlock biddingCompletion;
@property (nonatomic, assign) BOOL isBiddingRequest;
@property (nonatomic, assign) BOOL isPresentingAd;
@property (nonatomic, assign) BOOL hasShownCurrentShow;
@property (nonatomic, assign) BOOL hasClosedCurrentShow;
@property (nonatomic, assign) BOOL hasC2SCachedAd;
@property (nonatomic, assign) BOOL isDestroyed;
@property (nonatomic, assign) NSUInteger loadToken;

@end

@implementation ADMTradPlusSplashAdapter

- (instancetype)initWithServerExtra:(NSDictionary *)serverExtra
                         localExtra:(NSDictionary *)localExtra {
    self = [super init];
    if (self) {
        _serverExtra = [serverExtra copy];
        _localExtra = [localExtra copy];
    }
    return self;
}

#pragma mark - TradPlusBaseAdapter Overrides

- (void)loadAdWithWaterfallItem:(TradPlusAdWaterfallItem *)item {
    [super loadAdWithWaterfallItem:item];
    NSDictionary *serverExtra = [ADMTradPlusUtils serverExtraFromWaterfallItem:item];
    NSDictionary *localExtra = [ADMTradPlusUtils localExtraFromWaterfallItem:item];
    [self loadADWithInfo:serverExtra localInfo:localExtra completion:nil];
}

- (void)getC2SBiddingWithWaterfallItem:(TradPlusAdWaterfallItem *)item {
    [super getC2SBiddingWithWaterfallItem:item];
    NSDictionary *serverExtra = [ADMTradPlusUtils serverExtraFromWaterfallItem:item];
    NSDictionary *localExtra = [ADMTradPlusUtils localExtraFromWaterfallItem:item];
    __weak typeof(self) weakSelf = self;
    [self startBiddingRequestWithInfo:serverExtra
                            localInfo:localExtra
                           completion:^(TPBidInfo *_Nullable bidInfo, NSError *_Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (bidInfo && bidInfo.isValid) {
            NSString *fallbackEcpm = [ADMTradPlusUtils parseECPMYuanStringFromCents:strongSelf.biddingNotice.bidPriceCents];
            NSString *ecpmStr = bidInfo.price.length > 0 ? bidInfo.price : fallbackEcpm;
            [strongSelf finishC2SBiddingWithEcpm:ecpmStr];
        } else {
            NSString *errMsg = error.localizedDescription ?: (bidInfo.errorMessage ?: @"C2S Bidding failed");
            [strongSelf failC2SBiddingWithErrorStr:errMsg];
        }
    }];
}

- (BOOL)isReady {
    return [self isAdReady];
}

- (id)getCustomObject {
    return self.customAdObj;
}

- (BOOL)extraActWithEvent:(NSString *)event info:(NSDictionary *)info {
    return [ADMTradPlusUtils handleAdapterExtraEvent:event info:info forAdapter:self];
}

- (void)showAdInWindow:(UIWindow *)window bottomView:(UIView *)bottomView {
    [super showAdInWindow:window bottomView:bottomView];
    UIViewController *rootVC = window.rootViewController;
    if (!rootVC && [self.localExtra[ADMTradPlusExtraRootViewController] isKindOfClass:[UIViewController class]]) {
        rootVC = self.localExtra[ADMTradPlusExtraRootViewController];
    }
    [self showSplashInContainerView:window viewController:rootVC];
}

- (void)showAdFromRootViewController:(UIViewController *)rootViewController {
    [super showAdFromRootViewController:rootViewController];
    UIView *containerView = rootViewController.view.window ?: rootViewController.view;
    if (!containerView && [self.localExtra[ADMTradPlusExtraWindow] isKindOfClass:[UIView class]]) {
        containerView = self.localExtra[ADMTradPlusExtraWindow];
    }
    [self showSplashInContainerView:containerView viewController:rootViewController];
}

- (void)biddingSuccessWithSecondInfo:(NSDictionary *)info {
    [super biddingSuccessWithSecondInfo:info];
    [self.biddingNotice handleTradPlusWinInfo:info];
}

- (void)biddingFailWithWinInfo:(NSDictionary *)info {
    [super biddingFailWithWinInfo:info];
    [self.biddingNotice handleTradPlusLossInfo:info];
    [self destroy];
}

#pragma mark - Direct / Dictionary Entrypoints

- (void)loadADWithInfo:(NSDictionary *)serverExtra
             localInfo:(NSDictionary *)localExtra
            completion:(TPAdLoadCompletionBlock)completion {
    self.serverExtra = serverExtra;
    self.localExtra = localExtra;
    self.loadCompletion = completion;
    self.isBiddingRequest = NO;

    // C2S Cached Ad Reuse
    if (self.hasC2SCachedAd && self.splashAd != nil && [self.splashAd isReady]) {
        self.hasC2SCachedAd = NO;
        self.customAdObj = self.splashAd;
        if (self.biddingNotice && !self.biddingNotice.hasNotified) {
            [self notifyBidWinWithPrice:self.biddingNotice.bidPriceCents secondPrice:0];
        }
        double ecpmCents = [ADMTradPlusUtils parseECPMCentsFromString:[self.splashAd getECPMLevel]];
        NSDictionary *asset = @{
            @"splashAd": self.splashAd,
            @"unit_id": [ADMTradPlusUtils placementIDFromServerExtra:self.serverExtra localExtra:self.localExtra] ?: @"",
            @"ecpm_cents": @(ecpmCents)
        };
        [self AdLoaded];
        if (self.loadCompletion) {
            TPAdLoadCompletionBlock block = self.loadCompletion;
            self.loadCompletion = nil;
            block(@[asset], nil);
        }
        if ([self.delegate respondsToSelector:@selector(tradPlusAdapterDidLoad:extra:)]) {
            [self.delegate tradPlusAdapterDidLoad:self extra:asset];
        }
        return;
    }

    [self performLoadOrBidding];
}

- (void)startBiddingRequestWithInfo:(NSDictionary *)serverExtra
                          localInfo:(NSDictionary *)localExtra
                         completion:(TPBiddingCompletionBlock)completion {
    self.serverExtra = serverExtra;
    self.localExtra = localExtra;
    self.biddingCompletion = completion;
    self.isBiddingRequest = YES;
    self.hasC2SCachedAd = NO;
    [self performLoadOrBidding];
}

+ (void)startBiddingRequestWithInfo:(NSDictionary *)serverExtra
                          localInfo:(NSDictionary *)localExtra
                         completion:(TPBiddingCompletionBlock)completion {
    static NSMutableSet<ADMTradPlusSplashAdapter *> *activeBidders = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        activeBidders = [NSMutableSet set];
    });

    ADMTradPlusSplashAdapter *adapter = [[self alloc] initWithServerExtra:serverExtra localExtra:localExtra];
    @synchronized (activeBidders) {
        [activeBidders addObject:adapter];
    }

    [adapter startBiddingRequestWithInfo:serverExtra
                               localInfo:localExtra
                              completion:^(TPBidInfo *_Nullable bidInfo, NSError *_Nullable error) {
        if (completion) {
            completion(bidInfo, error);
        }
        @synchronized (activeBidders) {
            [activeBidders removeObject:adapter];
        }
    }];
}

- (void)performLoadOrBidding {
    self.isDestroyed = NO;
    NSUInteger requestToken = ++self.loadToken;
    NSString *placementID = [ADMTradPlusUtils placementIDFromServerExtra:self.serverExtra localExtra:self.localExtra];
    if (placementID.length == 0) {
        NSError *err = [ADMTradPlusUtils errorWithCode:ADMTradPlusErrorCodeInvalidParameters
                                           description:@"Missing placement_id / slot_id for Splash Ad"];
        [self handleFailureWithError:err];
        return;
    }

    __weak typeof(self) weakSelf = self;
    [[ADMTradPlusSDKInitManager sharedInstance] initializeSDKWithServerExtra:self.serverExtra
                                                                  localExtra:self.localExtra
                                                                  completion:^(BOOL success, NSError *_Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || strongSelf.isDestroyed || strongSelf.loadToken != requestToken) {
            return;
        }
        if (!success) {
            [strongSelf handleFailureWithError:error];
            return;
        }

        [ADMTradPlusUtils dispatchOnMainThread:^{
            if (strongSelf.isDestroyed || strongSelf.loadToken != requestToken) {
                return;
            }
            CGSize screenSize = [UIScreen mainScreen].bounds.size;
            if (screenSize.width <= 0 || screenSize.height <= 0) {
                screenSize = CGSizeMake(375.0, 812.0);
            }
            CGSize splashSize = [ADMTradPlusUtils adSizeFromServerExtra:strongSelf.serverExtra
                                                             localExtra:strongSelf.localExtra
                                                            defaultSize:screenSize];
            ADMSplashAd *ad = [[ADMSplashAd alloc] init];
            ad.adUnitTag = placementID;
            ad.adSize = splashSize;
            ad.delegate = strongSelf;
            ad.fullScreenContentDelegate = strongSelf;
            ad.request = [ADMTradPlusUtils requestFromServerExtra:strongSelf.serverExtra
                                                       localExtra:strongSelf.localExtra];
            strongSelf.splashAd = ad;
            strongSelf.customAdObj = ad;
            [ad load];
        }];
    }];
}

- (BOOL)isAdReady {
    return self.isPresentingAd || (self.splashAd != nil && [self.splashAd isReady]);
}

- (void)showSplashInContainerView:(UIView *)containerView
                   viewController:(UIViewController *)viewController {
    if (self.splashAd == nil || ![self.splashAd isReady]) {
        NSError *err = [ADMTradPlusUtils errorWithCode:ADMTradPlusErrorCodeAdNotReady
                                           description:@"Splash ad is not ready for presentation"];
        [self AdShowFailWithError:err];
        if ([self.delegate respondsToSelector:@selector(tradPlusAdapterDidFailToShow:error:)]) {
            [self.delegate tradPlusAdapterDidFailToShow:self error:err];
        }
        return;
    }

    self.isPresentingAd = YES;
    self.hasShownCurrentShow = NO;
    self.hasClosedCurrentShow = NO;
    self.isAdReady = YES;
    if (self.biddingNotice && !self.biddingNotice.hasNotified) {
        [self.biddingNotice handleTradPlusWinInfo:nil];
    }
    [ADMTradPlusUtils dispatchOnMainThread:^{
        UIView *hostView = containerView ?: viewController.view;
        if (!hostView) {
            self.isPresentingAd = NO;
            self.isAdReady = NO;
            NSError *err = [ADMTradPlusUtils errorWithCode:ADMTradPlusErrorCodeAdPresentFailed
                                               description:@"Splash container view or window is nil"];
            [self AdShowFailWithError:err];
            if ([self.delegate respondsToSelector:@selector(tradPlusAdapterDidFailToShow:error:)]) {
                [self.delegate tradPlusAdapterDidFailToShow:self error:err];
            }
            return;
        }
        [self cleanupInternalContainerView];
        UIView *wrapper = [[UIView alloc] initWithFrame:hostView.bounds];
        wrapper.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        wrapper.backgroundColor = [UIColor clearColor];
        [hostView addSubview:wrapper];
        self.internalContainerView = wrapper;
        [self.splashAd presentInContainerView:wrapper presentingViewController:viewController];
    }];
}

- (void)cleanupInternalContainerView {
    UIView *container = self.internalContainerView;
    self.internalContainerView = nil;
    if (container) {
        if ([NSThread isMainThread]) {
            [container removeFromSuperview];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [container removeFromSuperview];
            });
        }
    }
}

- (void)notifyBidWinWithPrice:(double)winPrice secondPrice:(double)secondPrice {
    [self.biddingNotice notifyBidWinWithPrice:winPrice secondPrice:secondPrice extra:nil];
}

- (void)notifyBidLossWithLossType:(TPBiddingLossType)lossType winPrice:(double)winPrice {
    [self.biddingNotice notifyBidLossWithLossType:lossType winPrice:winPrice extra:nil];
}

- (void)destroy {
    self.isDestroyed = YES;
    self.loadToken += 1;
    self.biddingNotice = nil;
    self.loadCompletion = nil;
    self.biddingCompletion = nil;
    [ADMTradPlusUtils dispatchOnMainThread:^{
        [self.splashAd stop];
        self.splashAd.delegate = nil;
        self.splashAd.fullScreenContentDelegate = nil;
        self.splashAd = nil;
        self.customAdObj = nil;
        self.biddingNotice = nil;
        self.loadCompletion = nil;
        self.biddingCompletion = nil;
        self.isPresentingAd = NO;
        self.hasShownCurrentShow = NO;
        self.isAdReady = NO;
        self.hasC2SCachedAd = NO;
        [self cleanupInternalContainerView];
    }];
}

- (void)destory {
    [self destroy];
}

#pragma mark - ADMSplashDelegate

- (void)splashAdDidReceiveAd:(ADMSplashAd *)ad {
    self.customAdObj = ad;
    NSString *placementID = [ADMTradPlusUtils placementIDFromServerExtra:self.serverExtra localExtra:self.localExtra] ?: @"";
    double ecpmCents = [ADMTradPlusUtils parseECPMCentsFromString:[ad getECPMLevel]];

    self.biddingNotice = [[ADMTradPlusBiddingNotice alloc] initWithPlacementID:placementID
                                                                        unitID:placementID
                                                                 bidPriceCents:ecpmCents
                                                                      adObject:ad];

    if (self.isBiddingRequest) {
        if (ecpmCents <= 0.0) {
            NSError *err = [ADMTradPlusUtils errorWithCode:ADMTradPlusErrorCodeBiddingFailed
                                               description:@"Splash C2S bidding returned invalid eCPM (<= 0)"];
            [self handleFailureWithError:err];
            return;
        }
        self.hasC2SCachedAd = YES;
        NSString *yuanPrice = [ADMTradPlusUtils parseECPMYuanStringFromCents:ecpmCents];
        TPBidInfo *bidInfo = [TPBidInfo bidInfoC2SWithPlacementID:placementID
                                                  unitGroupUnitID:placementID
                                               adapterClassString:NSStringFromClass([self class])
                                                            price:yuanPrice
                                                     currencyType:TPBiddingCurrencyTypeCNY
                                               expirationInterval:1800
                                                     customObject:ad
                                                    biddingNotice:self.biddingNotice];
        if (self.biddingCompletion) {
            TPBiddingCompletionBlock block = self.biddingCompletion;
            self.biddingCompletion = nil;
            block(bidInfo, nil);
        }
        return;
    }

    NSDictionary *asset = @{
        @"splashAd": ad,
        @"unit_id": placementID,
        @"ecpm_cents": @(ecpmCents)
    };
    [self AdLoaded];
    if (self.loadCompletion) {
        TPAdLoadCompletionBlock block = self.loadCompletion;
        self.loadCompletion = nil;
        block(@[asset], nil);
    }
    if ([self.delegate respondsToSelector:@selector(tradPlusAdapterDidLoad:extra:)]) {
        [self.delegate tradPlusAdapterDidLoad:self extra:asset];
    }
}

- (void)splashAd:(ADMSplashAd *)ad didFailToReceiveAdWithError:(NSError *)error {
    NSError *wrapped = [ADMTradPlusUtils errorFromADMError:error
                                               defaultCode:ADMTradPlusErrorCodeAdLoadFailed
                                        defaultDescription:@"Splash ad failed to receive"];
    [self handleFailureWithError:wrapped];
}

- (void)splashAdDidSkip:(ADMSplashAd *)ad {
    [self emitCloseOnceWithExtra:@{@"skipped": @(YES)}];
}

#pragma mark - ADMFullScreenContentDelegate

- (void)emitShowOnce {
    if (self.hasShownCurrentShow) {
        return;
    }
    self.hasShownCurrentShow = YES;
    self.isPresentingAd = YES;
    self.isAdReady = YES;
    [self AdShow];
    if ([self.delegate respondsToSelector:@selector(tradPlusAdapterDidShow:extra:)]) {
        [self.delegate tradPlusAdapterDidShow:self extra:nil];
    }
}

- (void)adWillPresentFullScreenContent:(id)ad {
    [self emitShowOnce];
}

- (void)adDidPresentFullScreenContent:(id)ad {
    [self emitShowOnce];
}

- (void)adDidRecordImpression:(id)ad {
    [self emitShowOnce];
}

- (void)ad:(id)ad didFailToPresentFullScreenContentWithError:(NSError *)error {
    [self cleanupInternalContainerView];
    self.isPresentingAd = NO;
    self.hasShownCurrentShow = NO;
    self.isAdReady = NO;
    NSError *wrapped = [ADMTradPlusUtils errorFromADMError:error
                                               defaultCode:ADMTradPlusErrorCodeAdPresentFailed
                                        defaultDescription:@"Splash ad failed to present"];
    [self AdShowFailWithError:wrapped];
    if ([self.delegate respondsToSelector:@selector(tradPlusAdapterDidFailToShow:error:)]) {
        [self.delegate tradPlusAdapterDidFailToShow:self error:wrapped];
    }
}

- (void)adDidRecordClick:(id)ad {
    self.isPresentingAd = YES;
    self.isAdReady = YES;
    [self AdClick];
    if ([self.delegate respondsToSelector:@selector(tradPlusAdapterDidClick:extra:)]) {
        [self.delegate tradPlusAdapterDidClick:self extra:nil];
    }
}

- (void)adDidDismissFullScreenContent:(id)ad {
    [self emitCloseOnceWithExtra:nil];
}

#pragma mark - Private

- (void)emitCloseOnceWithExtra:(NSDictionary *)extra {
    [self cleanupInternalContainerView];
    if (self.hasClosedCurrentShow) {
        return;
    }
    self.hasClosedCurrentShow = YES;
    [self emitShowOnce];
    [self AdClose];
    self.isPresentingAd = NO;
    self.hasShownCurrentShow = NO;
    self.isAdReady = NO;
    if ([self.delegate respondsToSelector:@selector(tradPlusAdapterDidClose:extra:)]) {
        [self.delegate tradPlusAdapterDidClose:self extra:extra];
    }
}

- (void)handleFailureWithError:(NSError *)error {
    self.hasC2SCachedAd = NO;
    NSError *finalError = error ?: [ADMTradPlusUtils errorWithCode:ADMTradPlusErrorCodeAdLoadFailed
                                                       description:@"Splash ad load failed"];
    if (self.isBiddingRequest) {
        if (self.biddingCompletion) {
            TPBiddingCompletionBlock block = self.biddingCompletion;
            self.biddingCompletion = nil;
            TPBidInfo *failedBid = [TPBidInfo bidInfoC2SWithErrorMessage:finalError.localizedDescription];
            block(failedBid, finalError);
        }
        return;
    }

    [self AdLoadFailWithError:finalError];
    if (self.loadCompletion) {
        TPAdLoadCompletionBlock block = self.loadCompletion;
        self.loadCompletion = nil;
        block(nil, finalError);
    }
    if ([self.delegate respondsToSelector:@selector(tradPlusAdapterDidFailToLoad:error:)]) {
        [self.delegate tradPlusAdapterDidFailToLoad:self error:finalError];
    }
}

@end

@implementation TradPlusAdMasterSplashAdapter
@end
