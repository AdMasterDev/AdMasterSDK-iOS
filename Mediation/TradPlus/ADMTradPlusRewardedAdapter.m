//
//  ADMTradPlusRewardedAdapter.m
//  TradPlusMediationAdMaster
//

#import "ADMTradPlusRewardedAdapter.h"
#import "ADMTradPlusConstants.h"
#import "ADMTradPlusSDKInitManager.h"
#import "ADMTradPlusUtils.h"

@interface ADMTradPlusRewardedAdapter ()

@property (nonatomic, strong, readwrite, nullable) ADMRewardedAd *rewardedAd;
@property (nonatomic, strong, readwrite, nullable) ADMTradPlusBiddingNotice *biddingNotice;
@property (nonatomic, copy, readwrite, nullable) NSDictionary *serverExtra;
@property (nonatomic, copy, readwrite, nullable) NSDictionary *localExtra;
@property (nonatomic, copy, nullable) TPAdLoadCompletionBlock loadCompletion;
@property (nonatomic, copy, nullable) TPBiddingCompletionBlock biddingCompletion;
@property (nonatomic, assign) BOOL isBiddingRequest;
@property (nonatomic, assign) BOOL isPresentingAd;
@property (nonatomic, assign) BOOL hasShownCurrentShow;
@property (nonatomic, assign) BOOL hasRewardedCurrentShow;
@property (nonatomic, assign) BOOL hasC2SCachedAd;
@property (nonatomic, assign) BOOL isDestroyed;
@property (nonatomic, assign) NSUInteger loadToken;

@end

@implementation ADMTradPlusRewardedAdapter

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

- (void)showAdFromRootViewController:(UIViewController *)rootViewController {
    [super showAdFromRootViewController:rootViewController];
    [self showRewardedVideoFromViewController:rootViewController];
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
    if (self.hasC2SCachedAd && self.rewardedAd != nil && [self.rewardedAd isReady]) {
        self.hasC2SCachedAd = NO;
        self.customAdObj = self.rewardedAd;
        if (self.biddingNotice && !self.biddingNotice.hasNotified) {
            [self notifyBidWinWithPrice:self.biddingNotice.bidPriceCents secondPrice:0];
        }
        double ecpmCents = [ADMTradPlusUtils parseECPMCentsFromString:[self.rewardedAd getECPMLevel]];
        NSDictionary *asset = @{
            @"rewardedAd": self.rewardedAd,
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
    static NSMutableSet<ADMTradPlusRewardedAdapter *> *activeBidders = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        activeBidders = [NSMutableSet set];
    });

    ADMTradPlusRewardedAdapter *adapter = [[self alloc] initWithServerExtra:serverExtra localExtra:localExtra];
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
                                           description:@"Missing placement_id / slot_id for Rewarded Video Ad"];
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
            ADMRewardedAd *ad = [[ADMRewardedAd alloc] init];
            ad.adUnitTag = placementID;
            ad.delegate = strongSelf;
            ad.fullScreenContentDelegate = strongSelf;
            ad.request = [ADMTradPlusUtils requestFromServerExtra:strongSelf.serverExtra
                                                       localExtra:strongSelf.localExtra];
            NSString *userID = [ADMTradPlusUtils userIDFromServerExtra:strongSelf.serverExtra
                                                            localExtra:strongSelf.localExtra];
            if (userID.length > 0) {
                ad.userID = userID;
            }
            NSString *extraInfo = [ADMTradPlusUtils customDataFromServerExtra:strongSelf.serverExtra
                                                                   localExtra:strongSelf.localExtra];
            if (extraInfo.length > 0) {
                ad.extraInfo = extraInfo;
            }
            strongSelf.rewardedAd = ad;
            strongSelf.customAdObj = ad;
            [ad load];
        }];
    }];
}

- (BOOL)isAdReady {
    return self.isPresentingAd || (self.rewardedAd != nil && [self.rewardedAd isReady]);
}

- (void)showRewardedVideoFromViewController:(UIViewController *)viewController {
    if (self.rewardedAd == nil || ![self.rewardedAd isReady]) {
        NSError *err = [ADMTradPlusUtils errorWithCode:ADMTradPlusErrorCodeAdNotReady
                                           description:@"Rewarded video ad is not ready for presentation"];
        [self AdShowFailWithError:err];
        if ([self.delegate respondsToSelector:@selector(tradPlusAdapterDidFailToShow:error:)]) {
            [self.delegate tradPlusAdapterDidFailToShow:self error:err];
        }
        return;
    }

    self.isPresentingAd = YES;
    self.hasShownCurrentShow = NO;
    self.hasRewardedCurrentShow = NO;
    self.isAdReady = YES;
    if (self.biddingNotice && !self.biddingNotice.hasNotified) {
        [self.biddingNotice handleTradPlusWinInfo:nil];
    }
    [ADMTradPlusUtils dispatchOnMainThread:^{
        if (viewController) {
            [self.rewardedAd presentFromViewController:viewController];
        } else {
            [self.rewardedAd presentFromRootViewController];
        }
    }];
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
        self.rewardedAd.delegate = nil;
        self.rewardedAd.fullScreenContentDelegate = nil;
        self.rewardedAd = nil;
        self.customAdObj = nil;
        self.biddingNotice = nil;
        self.loadCompletion = nil;
        self.biddingCompletion = nil;
        self.isPresentingAd = NO;
        self.hasShownCurrentShow = NO;
        self.isAdReady = NO;
        self.hasC2SCachedAd = NO;
    }];
}

- (void)destory {
    [self destroy];
}

#pragma mark - ADMRewardedDelegate

- (void)rewardedAdDidReceiveAd:(ADMRewardedAd *)ad {
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
                                               description:@"Rewarded C2S bidding returned invalid eCPM (<= 0)"];
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
        @"rewardedAd": ad,
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

- (void)rewardedAd:(ADMRewardedAd *)ad didFailToReceiveAdWithError:(NSError *)error {
    NSError *wrapped = [ADMTradPlusUtils errorFromADMError:error
                                               defaultCode:ADMTradPlusErrorCodeAdLoadFailed
                                        defaultDescription:@"Rewarded video ad failed to receive"];
    [self handleFailureWithError:wrapped];
}

- (void)rewardedAd:(ADMRewardedAd *)ad didFailToLoadWithError:(NSError *)error {
    NSError *wrapped = [ADMTradPlusUtils errorFromADMError:error
                                               defaultCode:ADMTradPlusErrorCodeAdLoadFailed
                                        defaultDescription:@"Rewarded video ad failed to load"];
    [self handleFailureWithError:wrapped];
}

- (void)rewardedAd:(ADMRewardedAd *)ad userDidEarnReward:(ADMReward *)reward {
    if (self.hasRewardedCurrentShow) {
        return;
    }
    self.hasRewardedCurrentShow = YES;
    self.isPresentingAd = YES;
    self.isAdReady = YES;
    [self emitShowOnce];
    NSDictionary *rewardExtra = @{
        @"reward_type": reward.type ?: @"Reward",
        @"reward_amount": @(reward.amount)
    };
    [self AdRewardedWithInfo:rewardExtra];
    if ([self.delegate respondsToSelector:@selector(tradPlusAdapterDidReward:extra:)]) {
        [self.delegate tradPlusAdapterDidReward:self extra:rewardExtra];
    }
}

- (void)rewardedAdDidRewardUser:(ADMRewardedAd *)ad {
    if (self.hasRewardedCurrentShow) {
        return;
    }
    self.hasRewardedCurrentShow = YES;
    self.isPresentingAd = YES;
    self.isAdReady = YES;
    [self emitShowOnce];
    NSDictionary *rewardExtra = @{
        @"reward_type": @"Reward",
        @"reward_amount": @(1)
    };
    [self AdRewardedWithInfo:rewardExtra];
    if ([self.delegate respondsToSelector:@selector(tradPlusAdapterDidReward:extra:)]) {
        [self.delegate tradPlusAdapterDidReward:self extra:rewardExtra];
    }
}

- (void)rewardedAdDidCompleteVideo:(ADMRewardedAd *)ad {
    [self AdVideoEnd];
    if ([self.delegate respondsToSelector:@selector(tradPlusAdapterVideoDidEnd:extra:)]) {
        [self.delegate tradPlusAdapterVideoDidEnd:self extra:nil];
    }
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
    [self AdVideoStart];
    if ([self.delegate respondsToSelector:@selector(tradPlusAdapterVideoDidStart:extra:)]) {
        [self.delegate tradPlusAdapterVideoDidStart:self extra:nil];
    }
}

- (void)adDidPresentFullScreenContent:(id)ad {
    [self adWillPresentFullScreenContent:ad];
}

- (void)adDidRecordImpression:(id)ad {
    [self emitShowOnce];
}

- (void)ad:(id)ad didFailToPresentFullScreenContentWithError:(NSError *)error {
    self.isPresentingAd = NO;
    self.hasShownCurrentShow = NO;
    self.isAdReady = NO;
    NSError *wrapped = [ADMTradPlusUtils errorFromADMError:error
                                               defaultCode:ADMTradPlusErrorCodeAdPresentFailed
                                        defaultDescription:@"Rewarded video ad failed to present"];
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
    [self emitShowOnce];
    [self AdClose];
    self.isPresentingAd = NO;
    self.hasShownCurrentShow = NO;
    self.isAdReady = NO;
    if ([self.delegate respondsToSelector:@selector(tradPlusAdapterDidClose:extra:)]) {
        [self.delegate tradPlusAdapterDidClose:self extra:nil];
    }
}

#pragma mark - Private

- (void)handleFailureWithError:(NSError *)error {
    self.hasC2SCachedAd = NO;
    NSError *finalError = error ?: [ADMTradPlusUtils errorWithCode:ADMTradPlusErrorCodeAdLoadFailed
                                                       description:@"Rewarded video ad load failed"];
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

@implementation TradPlusAdMasterRewardedAdapter
@end
