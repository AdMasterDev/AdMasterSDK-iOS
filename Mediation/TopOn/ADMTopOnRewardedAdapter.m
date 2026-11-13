#import "ADMTopOnRewardedAdapter.h"
#import "ADMTopOnConstants.h"
#import "ADMTopOnUtils.h"
#import "ADMTopOnSDKInitManager.h"

static NSMutableSet<ADMTopOnRewardedAdapter *> *ADMTopOnActiveBiddingRewardedAdapters(void) {
    static NSMutableSet<ADMTopOnRewardedAdapter *> *set = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        set = [NSMutableSet set];
    });
    return set;
}

static NSMutableArray<ADMTopOnRewardedAdapter *> *ADMTopOnCachedBiddingRewardedAdapters(void) {
    static NSMutableArray<ADMTopOnRewardedAdapter *> *list = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        list = [NSMutableArray array];
    });
    return list;
}

@interface ADMTopOnRewardedAdapter ()

@property (nonatomic, strong, nullable) ADMRewardedAd *rewardedAd;
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

static void ADMTopOnRegisterCachedRewardedAdapter(ADMTopOnRewardedAdapter *adapter) {
    if (!adapter) {
        return;
    }
    @synchronized (ADMTopOnCachedBiddingRewardedAdapters()) {
        if (![ADMTopOnCachedBiddingRewardedAdapters() containsObject:adapter]) {
            [ADMTopOnCachedBiddingRewardedAdapters() addObject:adapter];
        }
    }
}

static void ADMTopOnUnregisterCachedRewardedAdapter(ADMTopOnRewardedAdapter *adapter) {
    if (!adapter) {
        return;
    }
    @synchronized (ADMTopOnCachedBiddingRewardedAdapters()) {
        [ADMTopOnCachedBiddingRewardedAdapters() removeObject:adapter];
    }
}

static ADMTopOnRewardedAdapter *_Nullable ADMTopOnConsumeCachedRewardedAdapter(NSString *_Nullable placementID,
                                                                               NSString *_Nullable unitID,
                                                                               id _Nullable customObject) {
    @synchronized (ADMTopOnCachedBiddingRewardedAdapters()) {
        NSMutableArray<ADMTopOnRewardedAdapter *> *pool = ADMTopOnCachedBiddingRewardedAdapters();
        NSIndexSet *staleIndexes = [pool indexesOfObjectsPassingTest:^BOOL(ADMTopOnRewardedAdapter *obj, NSUInteger idx, BOOL *stop) {
            return obj.isDestroyed || ![obj isAdReady];
        }];
        if (staleIndexes.count > 0) {
            [pool removeObjectsAtIndexes:staleIndexes];
        }
        NSMutableIndexSet *matchedIndexes = [NSMutableIndexSet indexSet];
        for (NSUInteger i = 0; i < pool.count; i++) {
            ADMTopOnRewardedAdapter *candidate = pool[i];
            if (customObject != nil) {
                if (candidate == customObject || candidate.rewardedAd == customObject) {
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
            ADMTopOnRewardedAdapter *winner = pool[idx];
            [pool removeObjectAtIndex:idx];
            return winner;
        }
        return nil;
    }
}

@implementation ADMTopOnRewardedAdapter

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
    if ([customObject isKindOfClass:[ADMTopOnRewardedAdapter class]]) {
        return [(ADMTopOnRewardedAdapter *)customObject isAdReady];
    }
    if ([customObject isKindOfClass:[ADMRewardedAd class]]) {
        return [(ADMRewardedAd *)customObject isReady];
    }
    return NO;
}

+ (void)showRewardedVideo:(id)rewardedVideo
         inViewController:(UIViewController *)viewController
                 delegate:(nullable id)delegate {
    id customObject = rewardedVideo;
    if ([rewardedVideo respondsToSelector:@selector(customObject)]) {
        id extracted = [rewardedVideo valueForKey:@"customObject"];
        if (extracted) {
            customObject = extracted;
        }
    }
    if ([customObject isKindOfClass:[ADMTopOnRewardedAdapter class]]) {
        ADMTopOnRewardedAdapter *adapter = (ADMTopOnRewardedAdapter *)customObject;
        if (delegate) {
            adapter.delegate = (id <ADMTopOnAdapterEventDelegate>)delegate;
        }
        [adapter showRewardedVideoInViewController:viewController];
    } else if ([customObject isKindOfClass:[ADMRewardedAd class]]) {
        ADMRewardedAd *ad = (ADMRewardedAd *)customObject;
        if ([ad.delegate isKindOfClass:[ADMTopOnRewardedAdapter class]]) {
            ADMTopOnRewardedAdapter *adapter = (ADMTopOnRewardedAdapter *)ad.delegate;
            if (delegate) {
                adapter.delegate = (id <ADMTopOnAdapterEventDelegate>)delegate;
            }
            [adapter showRewardedVideoInViewController:viewController];
        } else if ([ad isReady] && viewController) {
            [ad presentFromViewController:viewController];
        }
    }
}

+ (void)startBiddingRequestWithInfo:(NSDictionary *)serverExtra
                          localInfo:(nullable NSDictionary *)localExtra
                         completion:(ATBiddingCompletionBlock)completion {
    ADMTopOnRewardedAdapter *adapter = [[ADMTopOnRewardedAdapter alloc] init];
    @synchronized (ADMTopOnActiveBiddingRewardedAdapters()) {
        [ADMTopOnActiveBiddingRewardedAdapters() addObject:adapter];
    }
    [adapter startBiddingRequestWithInfo:serverExtra
                               localInfo:localExtra
                              completion:^(ATBidInfo *_Nullable bidInfo, NSError *_Nullable error) {
        if (completion) {
            completion(bidInfo, error);
        }
        @synchronized (ADMTopOnActiveBiddingRewardedAdapters()) {
            [ADMTopOnActiveBiddingRewardedAdapters() removeObject:adapter];
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

    ADMTopOnRewardedAdapter *cachedAdapter = nil;
    if ([self isAdReady] &&
        (placementID.length == 0 || [self.placementID isEqualToString:placementID]) &&
        (unitID.length == 0 || self.unitID.length == 0 || [self.unitID isEqualToString:unitID])) {
        ADMTopOnUnregisterCachedRewardedAdapter(self);
        cachedAdapter = self;
    } else {
        cachedAdapter = ADMTopOnConsumeCachedRewardedAdapter(placementID, unitID, customObject);
    }

    if (cachedAdapter && cachedAdapter.rewardedAd) {
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
    ADMTopOnUnregisterCachedRewardedAdapter(self);
    [self adm_resetCurrentAdInstance];
    self.serverExtra = serverExtra;
    self.localExtra = localExtra;
    self.bidCompletion = completion;
    self.loadCompletion = nil;
    self.isC2SBidding = YES;
    self.adReady = NO;
    [self adm_startLoadProcessWithGeneration:generation];
}

- (void)adm_adoptCachedBiddingAdapter:(ADMTopOnRewardedAdapter *)cachedAdapter
                           generation:(NSUInteger)generation {
    ADMRewardedAd *adoptedAd = cachedAdapter.rewardedAd;
    ADMTopOnBiddingNotice *adoptedNotice = cachedAdapter.biddingNotice;
    NSString *adoptedPlacementID = [ADMTopOnUtils placementIDFromServerExtra:self.serverExtra localExtra:self.localExtra] ?: cachedAdapter.placementID;
    NSString *adoptedUnitID = [ADMTopOnUtils unitIDFromServerExtra:self.serverExtra localExtra:self.localExtra];
    if (adoptedUnitID.length == 0) {
        adoptedUnitID = cachedAdapter.unitID ?: adoptedPlacementID ?: @"";
    }

    if (cachedAdapter != self) {
        [self adm_resetCurrentAdInstance];
        cachedAdapter.adReady = NO;
        cachedAdapter.rewardedAd = nil;
        cachedAdapter.biddingNotice = nil;
        [cachedAdapter destroy];
    }

    self.placementID = adoptedPlacementID;
    self.unitID = adoptedUnitID;
    self.rewardedAd = adoptedAd;
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
            ADMTopOnUnregisterCachedRewardedAdapter(strongSelf);
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
    if (self.rewardedAd) {
        self.rewardedAd.delegate = nil;
        self.rewardedAd.fullScreenContentDelegate = nil;
        self.rewardedAd = nil;
    }
}

- (void)adm_startLoadProcessWithGeneration:(NSUInteger)generation {
    NSString *appID = [ADMTopOnUtils appIDFromServerExtra:self.serverExtra localExtra:self.localExtra];
    NSString *placementID = [ADMTopOnUtils placementIDFromServerExtra:self.serverExtra localExtra:self.localExtra];
    if (appID.length == 0 || placementID.length == 0) {
        NSError *error = [ADMTopOnUtils errorWithCode:ADMTopOnErrorCodeInvalidParameters
                                          description:@"Missing app_id or placement_id for RewardedVideo"];
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
        [self adm_requestRewardedAdWithPlacementID:placementID generation:generation];
    }];
}

- (void)adm_requestRewardedAdWithPlacementID:(NSString *)placementID generation:(NSUInteger)generation {
    [ADMTopOnUtils dispatchOnMainThread:^{
        if (self.isDestroyed || self.requestGeneration != generation) {
            return;
        }
        [ADMTopOnUtils updateAdMasterRuntimeFromServerExtra:self.serverExtra localExtra:self.localExtra];

        ADMRewardedAd *rewardedAd = [[ADMRewardedAd alloc] init];
        rewardedAd.adUnitTag = placementID;
        rewardedAd.delegate = self;
        rewardedAd.fullScreenContentDelegate = self;
        rewardedAd.request = [ADMTopOnUtils requestFromServerExtra:self.serverExtra localExtra:self.localExtra];

        NSString *userID = [ADMTopOnUtils userIDFromServerExtra:self.serverExtra localExtra:self.localExtra];
        if (userID.length > 0) {
            rewardedAd.userID = userID;
        }
        NSString *customData = [ADMTopOnUtils customDataFromServerExtra:self.serverExtra localExtra:self.localExtra];
        if (customData.length > 0) {
            rewardedAd.extraInfo = customData;
        }

        self.rewardedAd = rewardedAd;
        [self.rewardedAd load];
    }];
}

- (BOOL)isAdReady {
    return !self.isDestroyed && self.adReady && self.rewardedAd != nil && [self.rewardedAd isReady];
}

- (void)showRewardedVideoInViewController:(UIViewController *)viewController {
    [ADMTopOnUtils dispatchOnMainThread:^{
        if (![self isAdReady]) {
            NSError *error = [ADMTopOnUtils errorWithCode:ADMTopOnErrorCodeAdNotReady
                                              description:@"RewardedVideo ad is not ready"];
            if ([self.delegate respondsToSelector:@selector(topOnAdapterDidFailToShow:error:)]) {
                [self.delegate topOnAdapterDidFailToShow:self error:error];
            }
            return;
        }
        ADMTopOnUnregisterCachedRewardedAdapter(self);
        self.rewardedAd.fullScreenContentDelegate = self;
        if (viewController) {
            [self.rewardedAd presentFromViewController:viewController];
        } else {
            [self.rewardedAd presentFromRootViewController];
        }
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
    ADMTopOnUnregisterCachedRewardedAdapter(self);
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
        ADMTopOnUnregisterCachedRewardedAdapter(self);
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

#pragma mark - ADMRewardedDelegate

- (void)rewardedAdDidReceiveAd:(ADMRewardedAd *)ad {
    NSUInteger callbackGen = self.requestGeneration;
    [ADMTopOnUtils dispatchOnMainThread:^{
        if (self.isDestroyed || callbackGen != self.requestGeneration || (self.rewardedAd && ad != self.rewardedAd)) {
            return;
        }
        self.rewardedAd = ad;
        self.adReady = YES;
        ad.delegate = self;
        ad.fullScreenContentDelegate = self;

        double ecpmCents = [ADMTopOnUtils parseECPMCentsFromString:[ad getECPMLevel]];
        NSString *priceStr = [NSString stringWithFormat:@"%.2f", ecpmCents];
        ADMTopOnBiddingNotice *notice = [[ADMTopOnBiddingNotice alloc] initWithAdObject:ad
                                                                               adFormat:@"RewardedVideo"
                                                                          bidPriceCents:ecpmCents];
        self.biddingNotice = notice;
        __weak typeof(self) weakSelf = self;
        __weak ADMTopOnBiddingNotice *weakNotice = notice;
        notice.lossInvalidateHandler = ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf && !strongSelf.isDestroyed &&
                strongSelf.requestGeneration == callbackGen &&
                strongSelf.biddingNotice == weakNotice) {
                ADMTopOnUnregisterCachedRewardedAdapter(strongSelf);
                [strongSelf destroy];
            }
        };

        if (self.isC2SBidding && self.bidCompletion) {
            NSString *unitID = [ADMTopOnUtils unitIDFromServerExtra:self.serverExtra localExtra:self.localExtra];
            if (unitID.length == 0) {
                unitID = self.placementID ?: @"";
            }
            self.unitID = unitID;
            ADMTopOnRegisterCachedRewardedAdapter(self);
            ATBidInfo *bidInfo = [ATBidInfo bidInfoC2SWithPlacementID:self.placementID ?: @""
                                                      unitGroupUnitID:unitID
                                                   adapterClassString:NSStringFromClass([self class])
                                                                price:priceStr
                                                         currencyType:ADM_TOPON_BIDDING_CURRENCY_CNY_CENTS
                                                   expirationInterval:3600
                                                         customObject:ad];
            ATBiddingCompletionBlock bidComp = self.bidCompletion;
            self.bidCompletion = nil;
            bidComp(bidInfo, nil);
        }

        if (self.loadCompletion) {
            ATADLoadCompletionBlock loadComp = self.loadCompletion;
            self.loadCompletion = nil;
            loadComp(@[@{@"ad": ad, @"ecpm": priceStr}], nil);
        }

        if ([self.delegate respondsToSelector:@selector(topOnAdapterDidLoad:extra:)]) {
            [self.delegate topOnAdapterDidLoad:self extra:@{@"ecpm": @(ecpmCents)}];
        }
    }];
}

- (void)rewardedAd:(ADMRewardedAd *)ad didFailToReceiveAdWithError:(NSError *)error {
    if (self.isDestroyed || (self.rewardedAd && ad != self.rewardedAd)) {
        return;
    }
    NSError *mappedError = [ADMTopOnUtils errorFromADMError:(ADMError *)error
                                                defaultCode:ADMTopOnErrorCodeAdLoadFailed
                                         defaultDescription:@"RewardedVideo load failed"];
    [self adm_handleLoadFailureWithError:mappedError generation:self.requestGeneration];
}

- (void)rewardedAd:(ADMRewardedAd *)ad didFailToLoadWithError:(NSError *)error {
    [self rewardedAd:ad didFailToReceiveAdWithError:error];
}

- (void)rewardedAd:(ADMRewardedAd *)ad userDidEarnReward:(ADMReward *)reward {
    [ADMTopOnUtils dispatchOnMainThread:^{
        if (self.isDestroyed) {
            return;
        }
        NSMutableDictionary *extra = [NSMutableDictionary dictionary];
        if (reward.type) {
            extra[@"reward_type"] = reward.type;
        }
        extra[@"reward_amount"] = @(reward.amount);
        if ([self.delegate respondsToSelector:@selector(topOnAdapterDidReward:extra:)]) {
            [self.delegate topOnAdapterDidReward:self extra:extra];
        }
    }];
}

- (void)rewardedAdDidRewardUser:(ADMRewardedAd *)ad {
    [self rewardedAd:ad userDidEarnReward:[ADMReward rewardWithType:@"" amount:1]];
}

- (void)rewardedAdDidCompleteVideo:(ADMRewardedAd *)ad {
    [ADMTopOnUtils dispatchOnMainThread:^{
        if (self.isDestroyed) {
            return;
        }
        if ([self.delegate respondsToSelector:@selector(topOnAdapterVideoDidEnd:extra:)]) {
            [self.delegate topOnAdapterVideoDidEnd:self extra:nil];
        }
    }];
}

#pragma mark - ADMFullScreenContentDelegate

- (void)adWillPresentFullScreenContent:(id)ad {
    [ADMTopOnUtils dispatchOnMainThread:^{
        if (self.isDestroyed) {
            return;
        }
        if ([self.delegate respondsToSelector:@selector(topOnAdapterVideoDidStart:extra:)]) {
            [self.delegate topOnAdapterVideoDidStart:self extra:nil];
        }
    }];
}

- (void)adDidPresentFullScreenContent:(id)ad {
    [self adWillPresentFullScreenContent:ad];
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
        NSError *mappedError = [ADMTopOnUtils errorFromADMError:(ADMError *)error
                                                    defaultCode:ADMTopOnErrorCodeAdPresentFailed
                                             defaultDescription:@"RewardedVideo presentation failed"];
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
        if ([self.delegate respondsToSelector:@selector(topOnAdapterDidClose:extra:)]) {
            [self.delegate topOnAdapterDidClose:self extra:nil];
        }
    }];
}

@end
