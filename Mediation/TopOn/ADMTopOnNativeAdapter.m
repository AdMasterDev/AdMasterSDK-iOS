#import "ADMTopOnNativeAdapter.h"
#import "ADMTopOnConstants.h"
#import "ADMTopOnUtils.h"
#import "ADMTopOnSDKInitManager.h"

static NSMutableSet<ADMTopOnNativeAdapter *> *ADMTopOnActiveBiddingNativeAdapters(void) {
    static NSMutableSet<ADMTopOnNativeAdapter *> *set = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        set = [NSMutableSet set];
    });
    return set;
}

static NSMutableArray<ADMTopOnNativeAdapter *> *ADMTopOnCachedBiddingNativeAdapters(void) {
    static NSMutableArray<ADMTopOnNativeAdapter *> *list = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        list = [NSMutableArray array];
    });
    return list;
}

@interface ADMTopOnNativeAdapter ()

@property (nonatomic, strong, nullable) ADMNativeAdLoader *adLoader;
@property (nonatomic, strong, nullable) NSArray<ADMTopOnNativeAd *> *nativeAds;
@property (nonatomic, strong, nullable) NSArray<ADMNativeAdObject *> *rawNativeAdObjects;
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

static void ADMTopOnRegisterCachedNativeAdapter(ADMTopOnNativeAdapter *adapter) {
    if (!adapter) {
        return;
    }
    @synchronized (ADMTopOnCachedBiddingNativeAdapters()) {
        if (![ADMTopOnCachedBiddingNativeAdapters() containsObject:adapter]) {
            [ADMTopOnCachedBiddingNativeAdapters() addObject:adapter];
        }
    }
}

static void ADMTopOnUnregisterCachedNativeAdapter(ADMTopOnNativeAdapter *adapter) {
    if (!adapter) {
        return;
    }
    @synchronized (ADMTopOnCachedBiddingNativeAdapters()) {
        [ADMTopOnCachedBiddingNativeAdapters() removeObject:adapter];
    }
}

static BOOL ADMTopOnNativeAdapterHasValidAds(ADMTopOnNativeAdapter *adapter) {
    if (!adapter || adapter.isDestroyed || !adapter.adReady || adapter.nativeAds.count == 0) {
        return NO;
    }
    for (ADMTopOnNativeAd *nativeAd in adapter.nativeAds) {
        if ([nativeAd isExpired]) {
            return NO;
        }
    }
    for (ADMNativeAdObject *rawObj in adapter.rawNativeAdObjects) {
        if ([rawObj respondsToSelector:@selector(isExpired)] && [rawObj isExpired]) {
            return NO;
        }
    }
    return YES;
}

static ADMTopOnNativeAdapter *_Nullable ADMTopOnConsumeCachedNativeAdapter(NSString *_Nullable placementID,
                                                                           NSString *_Nullable unitID,
                                                                           id _Nullable customObject) {
    NSMutableArray<ADMTopOnNativeAdapter *> *expiredToDestroy = [NSMutableArray array];
    ADMTopOnNativeAdapter *selected = nil;
    @synchronized (ADMTopOnCachedBiddingNativeAdapters()) {
        NSMutableArray<ADMTopOnNativeAdapter *> *pool = ADMTopOnCachedBiddingNativeAdapters();
        NSIndexSet *staleIndexes = [pool indexesOfObjectsPassingTest:^BOOL(ADMTopOnNativeAdapter *obj, NSUInteger idx, BOOL *stop) {
            BOOL valid = ADMTopOnNativeAdapterHasValidAds(obj);
            if (!valid && !obj.isDestroyed) {
                [expiredToDestroy addObject:obj];
            }
            return !valid;
        }];
        if (staleIndexes.count > 0) {
            [pool removeObjectsAtIndexes:staleIndexes];
        }
        NSMutableIndexSet *matchedIndexes = [NSMutableIndexSet indexSet];
        for (NSUInteger i = 0; i < pool.count; i++) {
            ADMTopOnNativeAdapter *candidate = pool[i];
            if (customObject != nil) {
                if (candidate == customObject || [candidate.nativeAds containsObject:customObject] || [candidate.rawNativeAdObjects containsObject:customObject]) {
                    [pool removeObjectAtIndex:i];
                    selected = candidate;
                    break;
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
        if (!selected && matchedIndexes.count == 1) {
            NSUInteger idx = matchedIndexes.firstIndex;
            selected = pool[idx];
            [pool removeObjectAtIndex:idx];
        }
    }
    for (ADMTopOnNativeAdapter *stale in expiredToDestroy) {
        [stale destroy];
    }
    return selected;
}

@implementation ADMTopOnNativeAdapter

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
    if ([customObject isKindOfClass:[ADMTopOnNativeAdapter class]]) {
        return ADMTopOnNativeAdapterHasValidAds((ADMTopOnNativeAdapter *)customObject);
    }
    if ([customObject isKindOfClass:[ADMTopOnNativeAd class]]) {
        return ![(ADMTopOnNativeAd *)customObject isExpired];
    }
    if ([customObject isKindOfClass:[ADMNativeAdObject class]]) {
        return ![(ADMNativeAdObject *)customObject isExpired];
    }
    return NO;
}

+ (void)startBiddingRequestWithInfo:(NSDictionary *)serverExtra
                          localInfo:(nullable NSDictionary *)localExtra
                         completion:(ATBiddingCompletionBlock)completion {
    ADMTopOnNativeAdapter *adapter = [[ADMTopOnNativeAdapter alloc] init];
    @synchronized (ADMTopOnActiveBiddingNativeAdapters()) {
        [ADMTopOnActiveBiddingNativeAdapters() addObject:adapter];
    }
    [adapter startBiddingRequestWithInfo:serverExtra
                               localInfo:localExtra
                              completion:^(ATBidInfo *_Nullable bidInfo, NSError *_Nullable error) {
        if (completion) {
            completion(bidInfo, error);
        }
        @synchronized (ADMTopOnActiveBiddingNativeAdapters()) {
            [ADMTopOnActiveBiddingNativeAdapters() removeObject:adapter];
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

    ADMTopOnNativeAdapter *cachedAdapter = nil;
    if (ADMTopOnNativeAdapterHasValidAds(self) &&
        (placementID.length == 0 || [self.placementID isEqualToString:placementID]) &&
        (unitID.length == 0 || self.unitID.length == 0 || [self.unitID isEqualToString:unitID])) {
        ADMTopOnUnregisterCachedNativeAdapter(self);
        cachedAdapter = self;
    } else {
        ADMTopOnUnregisterCachedNativeAdapter(self);
        cachedAdapter = ADMTopOnConsumeCachedNativeAdapter(placementID, unitID, customObject);
    }

    if (cachedAdapter && ADMTopOnNativeAdapterHasValidAds(cachedAdapter)) {
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
    ADMTopOnUnregisterCachedNativeAdapter(self);
    [self adm_resetCurrentAdInstance];
    self.serverExtra = serverExtra;
    self.localExtra = localExtra;
    self.bidCompletion = completion;
    self.loadCompletion = nil;
    self.isC2SBidding = YES;
    self.adReady = NO;
    [self adm_startLoadProcessWithGeneration:generation];
}

- (void)adm_adoptCachedBiddingAdapter:(ADMTopOnNativeAdapter *)cachedAdapter
                           generation:(NSUInteger)generation {
    NSArray<ADMTopOnNativeAd *> *adoptedAds = cachedAdapter.nativeAds;
    NSArray<ADMNativeAdObject *> *adoptedRawObjects = cachedAdapter.rawNativeAdObjects;
    ADMNativeAdLoader *adoptedLoader = cachedAdapter.adLoader;
    ADMTopOnBiddingNotice *adoptedNotice = cachedAdapter.biddingNotice;
    NSString *adoptedPlacementID = [ADMTopOnUtils placementIDFromServerExtra:self.serverExtra localExtra:self.localExtra] ?: cachedAdapter.placementID;
    NSString *adoptedUnitID = [ADMTopOnUtils unitIDFromServerExtra:self.serverExtra localExtra:self.localExtra];
    if (adoptedUnitID.length == 0) {
        adoptedUnitID = cachedAdapter.unitID ?: adoptedPlacementID ?: @"";
    }

    if (cachedAdapter != self) {
        [self adm_resetCurrentAdInstance];
        cachedAdapter.adReady = NO;
        cachedAdapter.nativeAds = nil;
        cachedAdapter.rawNativeAdObjects = nil;
        cachedAdapter.adLoader = nil;
        cachedAdapter.biddingNotice = nil;
        [cachedAdapter destroy];
    }

    self.placementID = adoptedPlacementID;
    self.unitID = adoptedUnitID;
    self.adLoader = adoptedLoader;
    self.adLoader.delegate = self;
    self.nativeAds = adoptedAds;
    self.rawNativeAdObjects = adoptedRawObjects;
    self.biddingNotice = adoptedNotice;
    self.adReady = YES;
    for (ADMTopOnNativeAd *nativeAd in self.nativeAds) {
        nativeAd.delegate = self.delegate;
    }

    __weak typeof(self) weakSelf = self;
    __weak ADMTopOnBiddingNotice *weakNotice = adoptedNotice;
    NSUInteger boundGeneration = generation;
    adoptedNotice.lossInvalidateHandler = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf && !strongSelf.isDestroyed &&
            strongSelf.requestGeneration == boundGeneration &&
            strongSelf.biddingNotice == weakNotice) {
            ADMTopOnUnregisterCachedNativeAdapter(strongSelf);
            [strongSelf destroy];
        }
    };

    [ADMTopOnUtils dispatchOnMainThread:^{
        if (self.isDestroyed || self.requestGeneration != generation) {
            return;
        }
        NSMutableArray<NSDictionary *> *assets = [NSMutableArray arrayWithCapacity:adoptedAds.count];
        for (NSUInteger i = 0; i < adoptedAds.count; i++) {
            ADMTopOnNativeAd *nativeAd = adoptedAds[i];
            id rawObj = (i < adoptedRawObjects.count) ? adoptedRawObjects[i] : nativeAd.nativeAdObject;
            if (rawObj) {
                [assets addObject:@{@"ad": nativeAd, @"native_object": rawObj}];
            } else {
                [assets addObject:@{@"ad": nativeAd}];
            }
        }
        ADMNativeAdObject *firstObj = adoptedRawObjects.firstObject ?: adoptedAds.firstObject.nativeAdObject;
        double ecpmCents = [ADMTopOnUtils parseECPMCentsFromString:[firstObj getECPMLevel]];
        if (self.loadCompletion) {
            ATADLoadCompletionBlock loadComp = self.loadCompletion;
            self.loadCompletion = nil;
            loadComp(assets, nil);
        }
        if ([self.delegate respondsToSelector:@selector(topOnAdapterDidLoad:extra:)]) {
            [self.delegate topOnAdapterDidLoad:self extra:@{
                @"ecpm": @(ecpmCents),
                @"native_ads": self.nativeAds ?: @[]
            }];
        }
    }];
}

- (void)adm_resetCurrentAdInstance {
    self.biddingNotice.lossInvalidateHandler = nil;
    self.biddingNotice = nil;
    self.adLoader.delegate = nil;
    self.adLoader = nil;
    for (ADMTopOnNativeAd *nativeAd in self.nativeAds) {
        [nativeAd unregisterView];
    }
    self.nativeAds = nil;
    self.rawNativeAdObjects = nil;
}

- (void)adm_startLoadProcessWithGeneration:(NSUInteger)generation {
    NSString *appID = [ADMTopOnUtils appIDFromServerExtra:self.serverExtra localExtra:self.localExtra];
    NSString *placementID = [ADMTopOnUtils placementIDFromServerExtra:self.serverExtra localExtra:self.localExtra];
    if (appID.length == 0 || placementID.length == 0) {
        NSError *error = [ADMTopOnUtils errorWithCode:ADMTopOnErrorCodeInvalidParameters
                                          description:@"Missing app_id or placement_id for Native"];
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
        [self adm_requestNativeAdWithPlacementID:placementID generation:generation];
    }];
}

- (void)adm_requestNativeAdWithPlacementID:(NSString *)placementID generation:(NSUInteger)generation {
    [ADMTopOnUtils dispatchOnMainThread:^{
        if (self.isDestroyed || self.requestGeneration != generation) {
            return;
        }
        [ADMTopOnUtils updateAdMasterRuntimeFromServerExtra:self.serverExtra localExtra:self.localExtra];

        ADMNativeAdLoader *loader = [[ADMNativeAdLoader alloc] init];
        loader.adUnitTag = placementID;
        loader.delegate = self;
        loader.request = [ADMTopOnUtils requestFromServerExtra:self.serverExtra localExtra:self.localExtra];

        self.adLoader = loader;
        [self.adLoader load];
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
    ADMTopOnUnregisterCachedNativeAdapter(self);
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
        ADMTopOnUnregisterCachedNativeAdapter(self);
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

#pragma mark - ADMNativeAdLoaderDelegate

- (void)nativeAdLoader:(ADMNativeAdLoader *)loader didReceiveNativeAds:(NSArray<ADMNativeAdObject *> *)ads {
    NSUInteger callbackGen = self.requestGeneration;
    [ADMTopOnUtils dispatchOnMainThread:^{
        if (self.isDestroyed || callbackGen != self.requestGeneration || (self.adLoader && loader != self.adLoader)) {
            return;
        }
        if (ads.count == 0) {
            NSError *emptyError = [ADMTopOnUtils errorWithCode:ADMTopOnErrorCodeAdLoadFailed
                                                   description:@"Native ad list is empty"];
            [self adm_handleLoadFailureWithError:emptyError generation:callbackGen];
            return;
        }

        NSMutableArray<ADMTopOnNativeAd *> *wrappedList = [NSMutableArray arrayWithCapacity:ads.count];
        NSMutableArray<NSDictionary *> *assets = [NSMutableArray arrayWithCapacity:ads.count];
        for (ADMNativeAdObject *obj in ads) {
            ADMTopOnNativeAd *nativeAd = [[ADMTopOnNativeAd alloc] initWithNativeAdObject:obj];
            nativeAd.delegate = self.delegate;
            [wrappedList addObject:nativeAd];
            [assets addObject:@{@"ad": nativeAd, @"native_object": obj}];
        }
        self.nativeAds = [wrappedList copy];
        self.rawNativeAdObjects = [ads copy];
        self.adReady = YES;

        ADMNativeAdObject *firstObj = ads.firstObject;
        double ecpmCents = [ADMTopOnUtils parseECPMCentsFromString:[firstObj getECPMLevel]];
        NSString *priceStr = [NSString stringWithFormat:@"%.2f", ecpmCents];
        ADMTopOnBiddingNotice *notice = [[ADMTopOnBiddingNotice alloc] initWithAdObject:firstObj
                                                                               adFormat:@"Native"
                                                                          bidPriceCents:ecpmCents];
        self.biddingNotice = notice;
        __weak typeof(self) weakSelf = self;
        __weak ADMTopOnBiddingNotice *weakNotice = notice;
        notice.lossInvalidateHandler = ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf && !strongSelf.isDestroyed &&
                strongSelf.requestGeneration == callbackGen &&
                strongSelf.biddingNotice == weakNotice) {
                ADMTopOnUnregisterCachedNativeAdapter(strongSelf);
                [strongSelf destroy];
            }
        };

        if (self.isC2SBidding && self.bidCompletion) {
            NSString *unitID = [ADMTopOnUtils unitIDFromServerExtra:self.serverExtra localExtra:self.localExtra];
            if (unitID.length == 0) {
                unitID = self.placementID ?: @"";
            }
            self.unitID = unitID;
            ADMTopOnRegisterCachedNativeAdapter(self);
            ATBidInfo *bidInfo = [ATBidInfo bidInfoC2SWithPlacementID:self.placementID ?: @""
                                                      unitGroupUnitID:unitID
                                                   adapterClassString:NSStringFromClass([self class])
                                                                price:priceStr
                                                         currencyType:ADM_TOPON_BIDDING_CURRENCY_CNY_CENTS
                                                   expirationInterval:3600
                                                         customObject:wrappedList.firstObject];
            ATBiddingCompletionBlock bidComp = self.bidCompletion;
            self.bidCompletion = nil;
            bidComp(bidInfo, nil);
        }

        if (self.loadCompletion) {
            ATADLoadCompletionBlock loadComp = self.loadCompletion;
            self.loadCompletion = nil;
            loadComp(assets, nil);
        }

        if ([self.delegate respondsToSelector:@selector(topOnAdapterDidLoad:extra:)]) {
            [self.delegate topOnAdapterDidLoad:self extra:@{
                @"ecpm": @(ecpmCents),
                @"native_ads": self.nativeAds
            }];
        }
    }];
}

- (void)nativeAdLoader:(ADMNativeAdLoader *)loader
didFailToReceiveAdWithError:(NSError *)error
        nativeAdObject:(nullable ADMNativeAdObject *)adObject {
    if (self.isDestroyed || (self.adLoader && loader != self.adLoader)) {
        return;
    }
    if (adObject) {
        self.biddingNotice = [[ADMTopOnBiddingNotice alloc] initWithAdObject:adObject
                                                                    adFormat:@"Native"
                                                               bidPriceCents:0.0];
    }
    NSError *mappedError = [ADMTopOnUtils errorFromADMError:(ADMError *)error
                                                defaultCode:ADMTopOnErrorCodeAdLoadFailed
                                         defaultDescription:@"Native load failed"];
    [self adm_handleLoadFailureWithError:mappedError generation:self.requestGeneration];
}

@end
