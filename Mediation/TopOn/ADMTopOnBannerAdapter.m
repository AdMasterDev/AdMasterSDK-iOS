#import "ADMTopOnBannerAdapter.h"
#import "ADMTopOnConstants.h"
#import "ADMTopOnUtils.h"
#import "ADMTopOnSDKInitManager.h"

static NSMutableSet<ADMTopOnBannerAdapter *> *ADMTopOnActiveBiddingBannerAdapters(void) {
    static NSMutableSet<ADMTopOnBannerAdapter *> *set = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        set = [NSMutableSet set];
    });
    return set;
}

static NSMutableArray<ADMTopOnBannerAdapter *> *ADMTopOnCachedBiddingBannerAdapters(void) {
    static NSMutableArray<ADMTopOnBannerAdapter *> *list = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        list = [NSMutableArray array];
    });
    return list;
}

@interface ADMTopOnBannerAdapter ()

@property (nonatomic, strong, nullable) ADMBannerView *bannerView;
@property (nonatomic, strong, nullable) ADMTopOnBiddingNotice *biddingNotice;
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

static void ADMTopOnRegisterCachedBannerAdapter(ADMTopOnBannerAdapter *adapter) {
    if (!adapter) {
        return;
    }
    @synchronized (ADMTopOnCachedBiddingBannerAdapters()) {
        if (![ADMTopOnCachedBiddingBannerAdapters() containsObject:adapter]) {
            [ADMTopOnCachedBiddingBannerAdapters() addObject:adapter];
        }
    }
}

static void ADMTopOnUnregisterCachedBannerAdapter(ADMTopOnBannerAdapter *adapter) {
    if (!adapter) {
        return;
    }
    @synchronized (ADMTopOnCachedBiddingBannerAdapters()) {
        [ADMTopOnCachedBiddingBannerAdapters() removeObject:adapter];
    }
}

static ADMTopOnBannerAdapter *_Nullable ADMTopOnConsumeCachedBannerAdapter(NSString *_Nullable placementID,
                                                                           NSString *_Nullable unitID,
                                                                           id _Nullable customObject) {
    @synchronized (ADMTopOnCachedBiddingBannerAdapters()) {
        NSMutableArray<ADMTopOnBannerAdapter *> *pool = ADMTopOnCachedBiddingBannerAdapters();
        NSIndexSet *staleIndexes = [pool indexesOfObjectsPassingTest:^BOOL(ADMTopOnBannerAdapter *obj, NSUInteger idx, BOOL *stop) {
            return obj.isDestroyed || ![obj isAdReady];
        }];
        if (staleIndexes.count > 0) {
            [pool removeObjectsAtIndexes:staleIndexes];
        }
        NSMutableIndexSet *matchedIndexes = [NSMutableIndexSet indexSet];
        for (NSUInteger i = 0; i < pool.count; i++) {
            ADMTopOnBannerAdapter *candidate = pool[i];
            if (customObject != nil) {
                if (candidate == customObject || candidate.bannerView == customObject) {
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
            ADMTopOnBannerAdapter *winner = pool[idx];
            [pool removeObjectAtIndex:idx];
            return winner;
        }
        return nil;
    }
}

@implementation ADMTopOnBannerAdapter

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
    if ([customObject isKindOfClass:[ADMTopOnBannerAdapter class]]) {
        return [(ADMTopOnBannerAdapter *)customObject isAdReady];
    }
    if ([customObject isKindOfClass:[ADMBannerView class]]) {
        return YES;
    }
    return NO;
}

+ (void)startBiddingRequestWithInfo:(NSDictionary *)serverExtra
                          localInfo:(nullable NSDictionary *)localExtra
                         completion:(ATBiddingCompletionBlock)completion {
    ADMTopOnBannerAdapter *adapter = [[ADMTopOnBannerAdapter alloc] init];
    @synchronized (ADMTopOnActiveBiddingBannerAdapters()) {
        [ADMTopOnActiveBiddingBannerAdapters() addObject:adapter];
    }
    [adapter startBiddingRequestWithInfo:serverExtra
                               localInfo:localExtra
                              completion:^(ATBidInfo *_Nullable bidInfo, NSError *_Nullable error) {
        if (completion) {
            completion(bidInfo, error);
        }
        @synchronized (ADMTopOnActiveBiddingBannerAdapters()) {
            [ADMTopOnActiveBiddingBannerAdapters() removeObject:adapter];
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

    ADMTopOnBannerAdapter *cachedAdapter = nil;
    if ([self isAdReady] &&
        (placementID.length == 0 || [self.placementID isEqualToString:placementID]) &&
        (unitID.length == 0 || self.unitID.length == 0 || [self.unitID isEqualToString:unitID])) {
        ADMTopOnUnregisterCachedBannerAdapter(self);
        cachedAdapter = self;
    } else {
        cachedAdapter = ADMTopOnConsumeCachedBannerAdapter(placementID, unitID, customObject);
    }

    if (cachedAdapter && cachedAdapter.bannerView) {
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
    ADMTopOnUnregisterCachedBannerAdapter(self);
    [self adm_resetCurrentAdInstance];
    self.serverExtra = serverExtra;
    self.localExtra = localExtra;
    self.bidCompletion = completion;
    self.loadCompletion = nil;
    self.isC2SBidding = YES;
    self.adReady = NO;
    [self adm_startLoadProcessWithGeneration:generation];
}

- (void)adm_adoptCachedBiddingAdapter:(ADMTopOnBannerAdapter *)cachedAdapter
                           generation:(NSUInteger)generation {
    ADMBannerView *adoptedBanner = cachedAdapter.bannerView;
    ADMTopOnBiddingNotice *adoptedNotice = cachedAdapter.biddingNotice;
    NSString *adoptedPlacementID = [ADMTopOnUtils placementIDFromServerExtra:self.serverExtra localExtra:self.localExtra] ?: cachedAdapter.placementID;
    NSString *adoptedUnitID = [ADMTopOnUtils unitIDFromServerExtra:self.serverExtra localExtra:self.localExtra];
    if (adoptedUnitID.length == 0) {
        adoptedUnitID = cachedAdapter.unitID ?: adoptedPlacementID ?: @"";
    }

    if (cachedAdapter != self) {
        [self adm_resetCurrentAdInstance];
        cachedAdapter.adReady = NO;
        cachedAdapter.bannerView = nil;
        cachedAdapter.biddingNotice = nil;
        [cachedAdapter destroy];
    }

    self.placementID = adoptedPlacementID;
    self.unitID = adoptedUnitID;
    self.bannerView = adoptedBanner;
    self.biddingNotice = adoptedNotice;
    self.adReady = YES;
    adoptedBanner.delegate = self;

    __weak typeof(self) weakSelf = self;
    __weak ADMTopOnBiddingNotice *weakNotice = adoptedNotice;
    NSUInteger boundGeneration = generation;
    adoptedNotice.lossInvalidateHandler = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf && !strongSelf.isDestroyed &&
            strongSelf.requestGeneration == boundGeneration &&
            strongSelf.biddingNotice == weakNotice) {
            ADMTopOnUnregisterCachedBannerAdapter(strongSelf);
            [strongSelf destroy];
        }
    };

    [ADMTopOnUtils dispatchOnMainThread:^{
        if (self.isDestroyed || self.requestGeneration != generation) {
            return;
        }
        double ecpmCents = [ADMTopOnUtils parseECPMCentsFromString:[adoptedBanner getECPMLevel]];
        NSString *priceStr = [NSString stringWithFormat:@"%.2f", ecpmCents];
        if (self.loadCompletion) {
            ATADLoadCompletionBlock loadComp = self.loadCompletion;
            self.loadCompletion = nil;
            loadComp(@[@{@"ad": adoptedBanner, @"ecpm": priceStr}], nil);
        }
        if ([self.delegate respondsToSelector:@selector(topOnAdapterDidLoad:extra:)]) {
            [self.delegate topOnAdapterDidLoad:self extra:@{@"ecpm": @(ecpmCents), @"banner_view": adoptedBanner}];
        }
    }];
}

- (void)adm_resetCurrentAdInstance {
    self.biddingNotice.lossInvalidateHandler = nil;
    self.biddingNotice = nil;
    ADMBannerView *banner = self.bannerView;
    self.bannerView = nil;
    if (banner) {
        banner.delegate = nil;
        [ADMTopOnUtils dispatchOnMainThread:^{
            [banner removeFromSuperview];
        }];
    }
}

- (void)adm_startLoadProcessWithGeneration:(NSUInteger)generation {
    NSString *appID = [ADMTopOnUtils appIDFromServerExtra:self.serverExtra localExtra:self.localExtra];
    NSString *placementID = [ADMTopOnUtils placementIDFromServerExtra:self.serverExtra localExtra:self.localExtra];
    if (appID.length == 0 || placementID.length == 0) {
        NSError *error = [ADMTopOnUtils errorWithCode:ADMTopOnErrorCodeInvalidParameters
                                          description:@"Missing app_id or placement_id for Banner"];
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
        [self adm_requestBannerAdWithPlacementID:placementID generation:generation];
    }];
}

- (void)adm_requestBannerAdWithPlacementID:(NSString *)placementID generation:(NSUInteger)generation {
    [ADMTopOnUtils dispatchOnMainThread:^{
        if (self.isDestroyed || self.requestGeneration != generation) {
            return;
        }
        [ADMTopOnUtils updateAdMasterRuntimeFromServerExtra:self.serverExtra localExtra:self.localExtra];

        CGSize adSize = [ADMTopOnUtils adSizeFromServerExtra:self.serverExtra
                                                  localExtra:self.localExtra
                                                 defaultSize:CGSizeMake(320.0, 50.0)];

        ADMBannerView *bannerView = [[ADMBannerView alloc] initWithAdSize:adSize adUnitTag:placementID];
        bannerView.frame = CGRectMake(0, 0, adSize.width, adSize.height);
        bannerView.delegate = self;
        bannerView.request = [ADMTopOnUtils requestFromServerExtra:self.serverExtra localExtra:self.localExtra];

        self.bannerView = bannerView;
        [self.bannerView loadAd];
    }];
}

- (BOOL)isAdReady {
    return !self.isDestroyed && self.adReady && self.bannerView != nil && [self.bannerView isReady];
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
    ADMTopOnUnregisterCachedBannerAdapter(self);
    self.biddingNotice.lossInvalidateHandler = nil;
    [self adm_resetCurrentAdInstance];
    self.loadCompletion = nil;
    self.bidCompletion = nil;
}

#pragma mark - Private Failure Handling

- (void)adm_handleLoadFailureWithError:(NSError *)error generation:(NSUInteger)generation {
    [ADMTopOnUtils dispatchOnMainThread:^{
        if (self.isDestroyed || (generation > 0 && self.requestGeneration != generation)) {
            return;
        }
        self.adReady = NO;
        ADMTopOnUnregisterCachedBannerAdapter(self);
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

#pragma mark - ADMBannerDelegate

- (void)bannerViewDidReceiveAd:(ADMBannerView *)bannerView {
    NSUInteger callbackGen = self.requestGeneration;
    [ADMTopOnUtils dispatchOnMainThread:^{
        if (self.isDestroyed || callbackGen != self.requestGeneration || (self.bannerView && bannerView != self.bannerView)) {
            return;
        }
        self.bannerView = bannerView;
        self.adReady = YES;
        bannerView.delegate = self;

        double ecpmCents = [ADMTopOnUtils parseECPMCentsFromString:[bannerView getECPMLevel]];
        NSString *priceStr = [NSString stringWithFormat:@"%.2f", ecpmCents];
        ADMTopOnBiddingNotice *notice = [[ADMTopOnBiddingNotice alloc] initWithAdObject:bannerView
                                                                               adFormat:@"Banner"
                                                                          bidPriceCents:ecpmCents];
        self.biddingNotice = notice;
        __weak typeof(self) weakSelf = self;
        __weak ADMTopOnBiddingNotice *weakNotice = notice;
        notice.lossInvalidateHandler = ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf && !strongSelf.isDestroyed &&
                strongSelf.requestGeneration == callbackGen &&
                strongSelf.biddingNotice == weakNotice) {
                ADMTopOnUnregisterCachedBannerAdapter(strongSelf);
                [strongSelf destroy];
            }
        };

        if (self.isC2SBidding && self.bidCompletion) {
            NSString *unitID = [ADMTopOnUtils unitIDFromServerExtra:self.serverExtra localExtra:self.localExtra];
            if (unitID.length == 0) {
                unitID = self.placementID ?: @"";
            }
            self.unitID = unitID;
            ADMTopOnRegisterCachedBannerAdapter(self);
            ATBidInfo *bidInfo = [ATBidInfo bidInfoC2SWithPlacementID:self.placementID ?: @""
                                                      unitGroupUnitID:unitID
                                                   adapterClassString:NSStringFromClass([self class])
                                                                price:priceStr
                                                         currencyType:ADM_TOPON_BIDDING_CURRENCY_CNY_CENTS
                                                   expirationInterval:3600
                                                         customObject:bannerView];
            ATBiddingCompletionBlock bidComp = self.bidCompletion;
            self.bidCompletion = nil;
            bidComp(bidInfo, nil);
        }

        if (self.loadCompletion) {
            ATADLoadCompletionBlock loadComp = self.loadCompletion;
            self.loadCompletion = nil;
            loadComp(@[@{@"ad": bannerView, @"ecpm": priceStr}], nil);
        }

        if ([self.delegate respondsToSelector:@selector(topOnAdapterDidLoad:extra:)]) {
            [self.delegate topOnAdapterDidLoad:self extra:@{@"ecpm": @(ecpmCents), @"banner_view": bannerView}];
        }
    }];
}

- (void)bannerView:(ADMBannerView *)bannerView didFailToReceiveAdWithError:(NSError *)error {
    if (self.isDestroyed || (self.bannerView && bannerView != self.bannerView)) {
        return;
    }
    NSError *mappedError = [ADMTopOnUtils errorFromADMError:(ADMError *)error
                                                defaultCode:ADMTopOnErrorCodeAdLoadFailed
                                         defaultDescription:@"Banner load failed"];
    [self adm_handleLoadFailureWithError:mappedError generation:self.requestGeneration];
}

- (void)bannerViewDidRecordImpression:(ADMBannerView *)bannerView {
    [ADMTopOnUtils dispatchOnMainThread:^{
        if (self.isDestroyed) {
            return;
        }
        ADMTopOnUnregisterCachedBannerAdapter(self);
        if ([self.delegate respondsToSelector:@selector(topOnAdapterDidShow:extra:)]) {
            [self.delegate topOnAdapterDidShow:self extra:nil];
        }
    }];
}

- (void)bannerView:(ADMBannerView *)bannerView didFailToDisplayAdWithError:(NSError *)error {
    [ADMTopOnUtils dispatchOnMainThread:^{
        if (self.isDestroyed) {
            return;
        }
        NSError *mappedError = [ADMTopOnUtils errorFromADMError:(ADMError *)error
                                                    defaultCode:ADMTopOnErrorCodeAdPresentFailed
                                             defaultDescription:@"Banner display failed"];
        if ([self.delegate respondsToSelector:@selector(topOnAdapterDidFailToShow:error:)]) {
            [self.delegate topOnAdapterDidFailToShow:self error:mappedError];
        }
    }];
}

- (void)bannerViewDidRecordClick:(ADMBannerView *)bannerView {
    [ADMTopOnUtils dispatchOnMainThread:^{
        if (self.isDestroyed) {
            return;
        }
        if ([self.delegate respondsToSelector:@selector(topOnAdapterDidClick:extra:)]) {
            [self.delegate topOnAdapterDidClick:self extra:nil];
        }
    }];
}

- (void)bannerViewDidDismiss:(ADMBannerView *)bannerView {
    [ADMTopOnUtils dispatchOnMainThread:^{
        if (self.isDestroyed) {
            return;
        }
        if ([self.delegate respondsToSelector:@selector(topOnAdapterDidClose:extra:)]) {
            [self.delegate topOnAdapterDidClose:self extra:nil];
        }
    }];
}

@end
