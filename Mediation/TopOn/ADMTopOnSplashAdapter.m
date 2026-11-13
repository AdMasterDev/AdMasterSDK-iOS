#import "ADMTopOnSplashAdapter.h"
#import "ADMTopOnConstants.h"
#import "ADMTopOnUtils.h"
#import "ADMTopOnSDKInitManager.h"

static NSMutableSet<ADMTopOnSplashAdapter *> *ADMTopOnActiveBiddingSplashAdapters(void) {
    static NSMutableSet<ADMTopOnSplashAdapter *> *set = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        set = [NSMutableSet set];
    });
    return set;
}

static NSMutableArray<ADMTopOnSplashAdapter *> *ADMTopOnCachedBiddingSplashAdapters(void) {
    static NSMutableArray<ADMTopOnSplashAdapter *> *list = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        list = [NSMutableArray array];
    });
    return list;
}

@interface ADMTopOnSplashAdapter ()

@property (nonatomic, strong, nullable) ADMSplashAd *splashAd;
@property (nonatomic, strong, nullable) ADMTopOnBiddingNotice *biddingNotice;
@property (nonatomic, strong, nullable) UIView *internalContainerView;
@property (nonatomic, copy, nullable) NSDictionary *serverExtra;
@property (nonatomic, copy, nullable) NSDictionary *localExtra;
@property (nonatomic, copy, nullable) NSString *placementID;
@property (nonatomic, copy, nullable) NSString *unitID;
@property (nonatomic, copy, nullable) ATADLoadCompletionBlock loadCompletion;
@property (nonatomic, copy, nullable) ATBiddingCompletionBlock bidCompletion;
@property (nonatomic, assign) BOOL isC2SBidding;
@property (nonatomic, assign) BOOL adReady;
@property (nonatomic, assign) BOOL isDestroyed;
@property (nonatomic, assign) NSUInteger requestGeneration;

@end

static void ADMTopOnRegisterCachedSplashAdapter(ADMTopOnSplashAdapter *adapter) {
    if (!adapter) {
        return;
    }
    @synchronized (ADMTopOnCachedBiddingSplashAdapters()) {
        if (![ADMTopOnCachedBiddingSplashAdapters() containsObject:adapter]) {
            [ADMTopOnCachedBiddingSplashAdapters() addObject:adapter];
        }
    }
}

static void ADMTopOnUnregisterCachedSplashAdapter(ADMTopOnSplashAdapter *adapter) {
    if (!adapter) {
        return;
    }
    @synchronized (ADMTopOnCachedBiddingSplashAdapters()) {
        [ADMTopOnCachedBiddingSplashAdapters() removeObject:adapter];
    }
}

static ADMTopOnSplashAdapter *_Nullable ADMTopOnConsumeCachedSplashAdapter(NSString *_Nullable placementID,
                                                                           NSString *_Nullable unitID,
                                                                           id _Nullable customObject) {
    @synchronized (ADMTopOnCachedBiddingSplashAdapters()) {
        NSMutableArray<ADMTopOnSplashAdapter *> *pool = ADMTopOnCachedBiddingSplashAdapters();
        NSIndexSet *staleIndexes = [pool indexesOfObjectsPassingTest:^BOOL(ADMTopOnSplashAdapter *obj, NSUInteger idx, BOOL *stop) {
            return obj.isDestroyed || ![obj isAdReady];
        }];
        if (staleIndexes.count > 0) {
            [pool removeObjectsAtIndexes:staleIndexes];
        }
        NSMutableIndexSet *matchedIndexes = [NSMutableIndexSet indexSet];
        for (NSUInteger i = 0; i < pool.count; i++) {
            ADMTopOnSplashAdapter *candidate = pool[i];
            if (customObject != nil) {
                if (candidate == customObject || candidate.splashAd == customObject) {
                    [pool removeObjectAtIndex:i];
                    return candidate;
                }
                continue;
            }
            BOOL placementOK = (placementID.length == 0 || candidate.placementID.length == 0 || [candidate.placementID isEqualToString:placementID]);
            if (!placementOK) {
                continue;
            }
            if (unitID.length > 0 && candidate.unitID.length > 0) {
                if ([candidate.unitID isEqualToString:unitID]) {
                    [matchedIndexes addIndex:i];
                }
            } else if (placementID.length > 0 && candidate.placementID.length > 0 && [candidate.placementID isEqualToString:placementID]) {
                [matchedIndexes addIndex:i];
            }
        }
        if (matchedIndexes.count == 1) {
            NSUInteger idx = matchedIndexes.firstIndex;
            ADMTopOnSplashAdapter *winner = pool[idx];
            [pool removeObjectAtIndex:idx];
            return winner;
        }
        return nil;
    }
}

@implementation ADMTopOnSplashAdapter

- (instancetype)initWithNetworkCustomInfo:(nullable NSDictionary *)serverExtra
                                localInfo:(nullable NSDictionary *)localExtra {
    self = [super init];
    if (self) {
        _serverExtra = [serverExtra copy];
        _localExtra = [localExtra copy];
    }
    return self;
}

+ (void)bidRequestWithPlacementModel:(nullable id)placementModel
                      unitGroupModel:(nullable id)unitGroupModel
                                info:(NSDictionary *)info
                          completion:(ATBiddingCompletionBlock)completion {
    [self startBiddingRequestWithInfo:info localInfo:nil completion:completion];
}

+ (BOOL)adReadyWithCustomObject:(id)customObject info:(nullable NSDictionary *)info {
    if ([customObject isKindOfClass:[ADMTopOnSplashAdapter class]]) {
        return [(ADMTopOnSplashAdapter *)customObject isAdReady];
    }
    if ([customObject isKindOfClass:[ADMSplashAd class]]) {
        return [(ADMSplashAd *)customObject isReady];
    }
    return NO;
}

+ (void)showSplash:(id)splash withInfo:(nullable NSDictionary *)info {
    id customObject = splash;
    if ([splash respondsToSelector:@selector(customObject)]) {
        id extracted = [splash valueForKey:@"customObject"];
        if (extracted) {
            customObject = extracted;
        }
    }
    id delegate = info[@"delegate"];
    UIWindow *window = [info[@"window"] isKindOfClass:[UIWindow class]] ? info[@"window"] : nil;
    UIViewController *vc = [info[@"view_controller"] isKindOfClass:[UIViewController class]]
        ? info[@"view_controller"]
        : ([info[@"viewController"] isKindOfClass:[UIViewController class]] ? info[@"viewController"] : window.rootViewController);
    if ([customObject isKindOfClass:[ADMTopOnSplashAdapter class]]) {
        ADMTopOnSplashAdapter *adapter = (ADMTopOnSplashAdapter *)customObject;
        if (delegate) {
            adapter.delegate = (id <ADMTopOnAdapterEventDelegate>)delegate;
        }
        [adapter showSplashAdInWindow:window inViewController:vc parameter:info];
    } else if ([customObject isKindOfClass:[ADMSplashAd class]]) {
        ADMSplashAd *ad = (ADMSplashAd *)customObject;
        if ([ad.delegate isKindOfClass:[ADMTopOnSplashAdapter class]]) {
            ADMTopOnSplashAdapter *adapter = (ADMTopOnSplashAdapter *)ad.delegate;
            if (delegate) {
                adapter.delegate = (id <ADMTopOnAdapterEventDelegate>)delegate;
            }
            [adapter showSplashAdInWindow:window inViewController:vc parameter:info];
        } else {
            UIView *container = [info[@"container_view"] isKindOfClass:[UIView class]] ? info[@"container_view"] : (window ?: vc.view);
            if ([ad isReady] && container) {
                [ad presentInContainerView:container presentingViewController:vc];
            }
        }
    }
}

+ (void)startBiddingRequestWithInfo:(NSDictionary *)serverExtra
                          localInfo:(nullable NSDictionary *)localExtra
                         completion:(ATBiddingCompletionBlock)completion {
    ADMTopOnSplashAdapter *adapter = [[ADMTopOnSplashAdapter alloc] init];
    @synchronized (ADMTopOnActiveBiddingSplashAdapters()) {
        [ADMTopOnActiveBiddingSplashAdapters() addObject:adapter];
    }
    [adapter startBiddingRequestWithInfo:serverExtra
                               localInfo:localExtra
                              completion:^(ATBidInfo *_Nullable bidInfo, NSError *_Nullable error) {
        if (completion) {
            completion(bidInfo, error);
        }
        @synchronized (ADMTopOnActiveBiddingSplashAdapters()) {
            [ADMTopOnActiveBiddingSplashAdapters() removeObject:adapter];
        }
    }];
}

- (void)loadADWithInfo:(NSDictionary *)serverExtra
             localInfo:(nullable NSDictionary *)localExtra
            completion:(nullable ATADLoadCompletionBlock)completion {
    self.isDestroyed = NO;
    NSUInteger generation = ++self.requestGeneration;
    self.serverExtra = serverExtra;
    self.localExtra = localExtra;
    self.loadCompletion = completion;
    self.bidCompletion = nil;
    self.isC2SBidding = NO;

    NSString *placementID = [ADMTopOnUtils placementIDFromServerExtra:serverExtra localExtra:localExtra];
    NSString *unitID = [ADMTopOnUtils unitIDFromServerExtra:serverExtra localExtra:localExtra];
    id customObject = serverExtra[@"custom_object"] ?: serverExtra[@"customObject"] ?: localExtra[@"custom_object"] ?: localExtra[@"customObject"];

    ADMTopOnSplashAdapter *cachedAdapter = nil;
    if ([self isAdReady] &&
        (placementID.length == 0 || [self.placementID isEqualToString:placementID]) &&
        (unitID.length == 0 || self.unitID.length == 0 || [self.unitID isEqualToString:unitID])) {
        ADMTopOnUnregisterCachedSplashAdapter(self);
        cachedAdapter = self;
    } else {
        cachedAdapter = ADMTopOnConsumeCachedSplashAdapter(placementID, unitID, customObject);
    }

    if (cachedAdapter && cachedAdapter.splashAd) {
        [self adm_adoptCachedBiddingAdapter:cachedAdapter generation:generation];
        return;
    }

    [self adm_resetCurrentAdInstance];
    self.adReady = NO;
    [self adm_startLoadProcessWithGeneration:generation];
}

- (void)startBiddingRequestWithInfo:(NSDictionary *)serverExtra
                          localInfo:(nullable NSDictionary *)localExtra
                         completion:(ATBiddingCompletionBlock)completion {
    self.isDestroyed = NO;
    NSUInteger generation = ++self.requestGeneration;
    ADMTopOnUnregisterCachedSplashAdapter(self);
    [self adm_resetCurrentAdInstance];
    self.serverExtra = serverExtra;
    self.localExtra = localExtra;
    self.bidCompletion = completion;
    self.loadCompletion = nil;
    self.isC2SBidding = YES;
    self.adReady = NO;
    [self adm_startLoadProcessWithGeneration:generation];
}

- (void)adm_adoptCachedBiddingAdapter:(ADMTopOnSplashAdapter *)cachedAdapter
                           generation:(NSUInteger)generation {
    ADMSplashAd *adoptedAd = cachedAdapter.splashAd;
    ADMTopOnBiddingNotice *adoptedNotice = cachedAdapter.biddingNotice;
    NSString *adoptedPlacementID = [ADMTopOnUtils placementIDFromServerExtra:self.serverExtra localExtra:self.localExtra] ?: cachedAdapter.placementID;
    NSString *adoptedUnitID = [ADMTopOnUtils unitIDFromServerExtra:self.serverExtra localExtra:self.localExtra];
    if (adoptedUnitID.length == 0) {
        adoptedUnitID = cachedAdapter.unitID ?: adoptedPlacementID ?: @"";
    }

    if (cachedAdapter != self) {
        [self adm_resetCurrentAdInstance];
        cachedAdapter.adReady = NO;
        cachedAdapter.splashAd = nil;
        cachedAdapter.biddingNotice = nil;
        [cachedAdapter destroy];
    }

    self.placementID = adoptedPlacementID;
    self.unitID = adoptedUnitID;
    self.splashAd = adoptedAd;
    self.biddingNotice = adoptedNotice;
    self.adReady = YES;
    adoptedAd.delegate = self;
    adoptedAd.fullScreenContentDelegate = self;

    __weak typeof(self) weakSelf = self;
    __weak ADMTopOnBiddingNotice *weakNotice = adoptedNotice;
    NSUInteger boundGeneration = generation;
    adoptedNotice.lossInvalidateHandler = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf && !strongSelf.isDestroyed &&
            strongSelf.requestGeneration == boundGeneration &&
            strongSelf.biddingNotice == weakNotice) {
            ADMTopOnUnregisterCachedSplashAdapter(strongSelf);
            [strongSelf destroy];
        }
    };

    [ADMTopOnUtils dispatchOnMainThread:^{
        if (self.isDestroyed || self.requestGeneration != generation) {
            return;
        }
        double ecpmCents = [ADMTopOnUtils parseECPMCentsFromString:[adoptedAd getECPMLevel]];
        NSString *priceStr = [NSString stringWithFormat:@"%.2f", ecpmCents];
        if (self.loadCompletion) {
            ATADLoadCompletionBlock loadComp = self.loadCompletion;
            self.loadCompletion = nil;
            loadComp(@[@{@"ad": adoptedAd, @"ecpm": priceStr}], nil);
        }
        if ([self.delegate respondsToSelector:@selector(topOnAdapterDidLoad:extra:)]) {
            [self.delegate topOnAdapterDidLoad:self extra:@{@"ecpm": @(ecpmCents)}];
        }
    }];
}

- (void)adm_resetCurrentAdInstance {
    self.biddingNotice.lossInvalidateHandler = nil;
    self.biddingNotice = nil;
    ADMSplashAd *splash = self.splashAd;
    self.splashAd = nil;
    if (splash) {
        splash.delegate = nil;
        splash.fullScreenContentDelegate = nil;
        [splash stop];
    }
    [self adm_cleanupContainerView];
}

- (void)adm_startLoadProcessWithGeneration:(NSUInteger)generation {
    NSString *appID = [ADMTopOnUtils appIDFromServerExtra:self.serverExtra localExtra:self.localExtra];
    NSString *placementID = [ADMTopOnUtils placementIDFromServerExtra:self.serverExtra localExtra:self.localExtra];
    if (appID.length == 0 || placementID.length == 0) {
        NSError *error = [ADMTopOnUtils errorWithCode:ADMTopOnErrorCodeInvalidParameters
                                          description:@"Missing app_id or placement_id for Splash"];
        [self adm_handleLoadFailureWithError:error generation:generation];
        return;
    }
    self.placementID = placementID;
    self.unitID = [ADMTopOnUtils unitIDFromServerExtra:self.serverExtra localExtra:self.localExtra];

    __weak typeof(self) weakSelf = self;
    [[ADMTopOnSDKInitManager sharedInstance] initSDKWithAppID:appID
                                                  serverExtra:self.serverExtra
                                                   localExtra:self.localExtra
                                                   completion:^(BOOL success, NSError *_Nullable error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.isDestroyed || self.requestGeneration != generation) {
            return;
        }
        if (!success) {
            NSError *initError = error ?: [ADMTopOnUtils errorWithCode:ADMTopOnErrorCodeSDKInitFailed
                                                           description:@"AdMaster SDK initialization failed"];
            [self adm_handleLoadFailureWithError:initError generation:generation];
            return;
        }
        [self adm_requestSplashAdWithPlacementID:placementID generation:generation];
    }];
}

- (void)adm_requestSplashAdWithPlacementID:(NSString *)placementID generation:(NSUInteger)generation {
    [ADMTopOnUtils dispatchOnMainThread:^{
        if (self.isDestroyed || self.requestGeneration != generation) {
            return;
        }
        [ADMTopOnUtils updateAdMasterRuntimeFromServerExtra:self.serverExtra localExtra:self.localExtra];

        CGSize screenSize = [UIScreen mainScreen].bounds.size;
        CGSize defaultSize = CGSizeMake(MAX(screenSize.width, 200.0), MAX(screenSize.height, 200.0));
        CGSize adSize = [ADMTopOnUtils adSizeFromServerExtra:self.serverExtra
                                                  localExtra:self.localExtra
                                                 defaultSize:defaultSize];

        ADMSplashAd *splashAd = [[ADMSplashAd alloc] init];
        splashAd.adUnitTag = placementID;
        splashAd.adSize = CGSizeMake(MAX(adSize.width, 200.0), MAX(adSize.height, 200.0));
        splashAd.delegate = self;
        splashAd.fullScreenContentDelegate = self;
        splashAd.request = [ADMTopOnUtils requestFromServerExtra:self.serverExtra localExtra:self.localExtra];

        self.splashAd = splashAd;
        [self.splashAd load];
    }];
}

- (BOOL)isAdReady {
    return !self.isDestroyed && self.adReady && self.splashAd != nil && [self.splashAd isReady];
}

- (void)showSplashAdInWindow:(nullable UIWindow *)window
            inViewController:(nullable UIViewController *)viewController
                   parameter:(nullable NSDictionary *)parameter {
    [ADMTopOnUtils dispatchOnMainThread:^{
        if (![self isAdReady]) {
            NSError *error = [ADMTopOnUtils errorWithCode:ADMTopOnErrorCodeAdNotReady
                                              description:@"Splash ad is not ready"];
            if ([self.delegate respondsToSelector:@selector(topOnAdapterDidFailToShow:error:)]) {
                [self.delegate topOnAdapterDidFailToShow:self error:error];
            }
            return;
        }

        UIView *hostView = nil;
        UIView *paramContainer = parameter[@"container_view"] ?: parameter[@"containerView"];
        if ([paramContainer isKindOfClass:[UIView class]]) {
            hostView = paramContainer;
        } else if (window) {
            hostView = window;
        } else if (viewController.view) {
            hostView = viewController.view;
        }

        if (!hostView) {
            NSError *error = [ADMTopOnUtils errorWithCode:ADMTopOnErrorCodeInvalidContainer
                                              description:@"Splash container view or window is nil"];
            if ([self.delegate respondsToSelector:@selector(topOnAdapterDidFailToShow:error:)]) {
                [self.delegate topOnAdapterDidFailToShow:self error:error];
            }
            return;
        }

        ADMTopOnUnregisterCachedSplashAdapter(self);
        [self adm_cleanupContainerView];

        UIView *containerView = [[UIView alloc] initWithFrame:hostView.bounds];
        containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        containerView.backgroundColor = [UIColor clearColor];
        [hostView addSubview:containerView];
        self.internalContainerView = containerView;

        UIViewController *presentingVC = viewController ?: window.rootViewController;
        self.splashAd.fullScreenContentDelegate = self;
        [self.splashAd presentInContainerView:containerView presentingViewController:presentingVC];
    }];
}

- (void)didReceiveBidResult:(ATBidWinLossResult *)result {
    if (!result) {
        return;
    }
    if (result.bidResultType == ATBidWinLossResultTypeWin) {
        [self.biddingNotice notifyBidWinWithPrice:[result.winPrice doubleValue]
                                      secondPrice:[result.secondPrice doubleValue]
                                            extra:result.userInfoDic];
    } else if (result.bidResultType == ATBidWinLossResultTypeLoss) {
        [self.biddingNotice notifyBidLossWithLossType:result.lossReasonType
                                             winPrice:[result.winPrice doubleValue]
                                                extra:result.userInfoDic];
    }
}

- (void)notifyBidWinWithPrice:(double)price secondPrice:(double)secondPrice {
    [self.biddingNotice notifyBidWinWithPrice:price secondPrice:secondPrice extra:nil];
}

- (void)notifyBidLossWithLossType:(ATBiddingLossType)lossType winPrice:(double)winPrice {
    [self.biddingNotice notifyBidLossWithLossType:lossType winPrice:winPrice extra:nil];
}

- (void)destory {
    [self destroy];
}

- (void)destroy {
    self.isDestroyed = YES;
    self.requestGeneration++;
    self.adReady = NO;
    ADMTopOnUnregisterCachedSplashAdapter(self);
    self.biddingNotice.lossInvalidateHandler = nil;
    [self adm_resetCurrentAdInstance];
    self.loadCompletion = nil;
    self.bidCompletion = nil;
}

#pragma mark - Private Helpers

- (void)adm_cleanupContainerView {
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

- (void)adm_handleLoadFailureWithError:(NSError *)error generation:(NSUInteger)generation {
    [ADMTopOnUtils dispatchOnMainThread:^{
        if (self.isDestroyed || (generation > 0 && self.requestGeneration != generation)) {
            return;
        }
        self.adReady = NO;
        ADMTopOnUnregisterCachedSplashAdapter(self);
        if (self.isC2SBidding && self.bidCompletion) {
            ATBiddingCompletionBlock bidComp = self.bidCompletion;
            self.bidCompletion = nil;
            bidComp(nil, error);
        }
        if (self.loadCompletion) {
            ATADLoadCompletionBlock loadComp = self.loadCompletion;
            self.loadCompletion = nil;
            loadComp(nil, error);
        }
        if ([self.delegate respondsToSelector:@selector(topOnAdapterDidFailToLoad:error:)]) {
            [self.delegate topOnAdapterDidFailToLoad:self error:error];
        }
    }];
}

#pragma mark - ADMSplashDelegate

- (void)splashAdDidReceiveAd:(ADMSplashAd *)splashAd {
    NSUInteger callbackGen = self.requestGeneration;
    [ADMTopOnUtils dispatchOnMainThread:^{
        if (self.isDestroyed || callbackGen != self.requestGeneration || (self.splashAd && splashAd != self.splashAd)) {
            return;
        }
        self.splashAd = splashAd;
        self.adReady = YES;
        splashAd.delegate = self;
        splashAd.fullScreenContentDelegate = self;

        double ecpmCents = [ADMTopOnUtils parseECPMCentsFromString:[splashAd getECPMLevel]];
        NSString *priceStr = [NSString stringWithFormat:@"%.2f", ecpmCents];
        ADMTopOnBiddingNotice *notice = [[ADMTopOnBiddingNotice alloc] initWithAdObject:splashAd
                                                                               adFormat:@"Splash"
                                                                          bidPriceCents:ecpmCents];
        self.biddingNotice = notice;
        __weak typeof(self) weakSelf = self;
        __weak ADMTopOnBiddingNotice *weakNotice = notice;
        notice.lossInvalidateHandler = ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf && !strongSelf.isDestroyed &&
                strongSelf.requestGeneration == callbackGen &&
                strongSelf.biddingNotice == weakNotice) {
                ADMTopOnUnregisterCachedSplashAdapter(strongSelf);
                [strongSelf destroy];
            }
        };

        if (self.isC2SBidding && self.bidCompletion) {
            NSString *unitID = [ADMTopOnUtils unitIDFromServerExtra:self.serverExtra localExtra:self.localExtra];
            if (unitID.length == 0) {
                unitID = self.placementID ?: @"";
            }
            self.unitID = unitID;
            ADMTopOnRegisterCachedSplashAdapter(self);
            ATBidInfo *bidInfo = [ATBidInfo bidInfoC2SWithPlacementID:self.placementID ?: @""
                                                      unitGroupUnitID:unitID
                                                   adapterClassString:NSStringFromClass([self class])
                                                                price:priceStr
                                                         currencyType:ADM_TOPON_BIDDING_CURRENCY_CNY_CENTS
                                                   expirationInterval:3600
                                                         customObject:splashAd];
            ATBiddingCompletionBlock bidComp = self.bidCompletion;
            self.bidCompletion = nil;
            bidComp(bidInfo, nil);
        }

        if (self.loadCompletion) {
            ATADLoadCompletionBlock loadComp = self.loadCompletion;
            self.loadCompletion = nil;
            loadComp(@[@{@"ad": splashAd, @"ecpm": priceStr}], nil);
        }

        if ([self.delegate respondsToSelector:@selector(topOnAdapterDidLoad:extra:)]) {
            [self.delegate topOnAdapterDidLoad:self extra:@{@"ecpm": @(ecpmCents)}];
        }
    }];
}

- (void)splashAd:(ADMSplashAd *)splashAd didFailToReceiveAdWithError:(NSError *)error {
    if (self.isDestroyed || (self.splashAd && splashAd != self.splashAd)) {
        return;
    }
    NSError *mappedError = [ADMTopOnUtils errorFromADMError:(ADMError *)error
                                                defaultCode:ADMTopOnErrorCodeAdLoadFailed
                                         defaultDescription:@"Splash load failed"];
    [self adm_handleLoadFailureWithError:mappedError generation:self.requestGeneration];
}

- (void)splashAdDidSkip:(ADMSplashAd *)splashAd {
}

#pragma mark - ADMFullScreenContentDelegate

- (void)adWillPresentFullScreenContent:(id)ad {
}

- (void)adDidRecordImpression:(id)ad {
    [ADMTopOnUtils dispatchOnMainThread:^{
        if (self.isDestroyed) {
            return;
        }
        if ([self.delegate respondsToSelector:@selector(topOnAdapterDidShow:extra:)]) {
            [self.delegate topOnAdapterDidShow:self extra:nil];
        }
    }];
}

- (void)ad:(id)ad didFailToPresentFullScreenContentWithError:(NSError *)error {
    [ADMTopOnUtils dispatchOnMainThread:^{
        if (self.isDestroyed) {
            return;
        }
        self.adReady = NO;
        [self.splashAd stop];
        [self adm_cleanupContainerView];
        NSError *mappedError = [ADMTopOnUtils errorFromADMError:(ADMError *)error
                                                    defaultCode:ADMTopOnErrorCodeAdPresentFailed
                                             defaultDescription:@"Splash presentation failed"];
        if ([self.delegate respondsToSelector:@selector(topOnAdapterDidFailToShow:error:)]) {
            [self.delegate topOnAdapterDidFailToShow:self error:mappedError];
        }
    }];
}

- (void)adDidRecordClick:(id)ad {
    [ADMTopOnUtils dispatchOnMainThread:^{
        if (self.isDestroyed) {
            return;
        }
        if ([self.delegate respondsToSelector:@selector(topOnAdapterDidClick:extra:)]) {
            [self.delegate topOnAdapterDidClick:self extra:nil];
        }
    }];
}

- (void)adDidDismissFullScreenContent:(id)ad {
    [ADMTopOnUtils dispatchOnMainThread:^{
        if (self.isDestroyed) {
            return;
        }
        self.adReady = NO;
        [self.splashAd stop];
        [self adm_cleanupContainerView];
        if ([self.delegate respondsToSelector:@selector(topOnAdapterDidClose:extra:)]) {
            [self.delegate topOnAdapterDidClose:self extra:nil];
        }
    }];
}

@end
