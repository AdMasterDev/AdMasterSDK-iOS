//
//  ADMTradPlusInterstitialAdapter.m
//  TradPlusMediationAdMaster
//

#import "ADMTradPlusInterstitialAdapter.h"
#import "ADMTradPlusConstants.h"
#import "ADMTradPlusSDKInitManager.h"
#import "ADMTradPlusUtils.h"

@interface ADMTradPlusInterstitialAdapter ()

@property (nonatomic, strong, readwrite, nullable) ADMInterstitialAd *interstitialAd;
@property (nonatomic, strong, readwrite, nullable) ADMTradPlusBiddingNotice *biddingNotice;
@property (nonatomic, copy, readwrite, nullable) NSDictionary *serverExtra;
@property (nonatomic, copy, readwrite, nullable) NSDictionary *localExtra;
@property (nonatomic, copy, nullable) TPAdLoadCompletionBlock loadCompletion;
@property (nonatomic, copy, nullable) TPBiddingCompletionBlock biddingCompletion;
@property (nonatomic, assign) BOOL isBiddingRequest;
@property (nonatomic, assign) BOOL isPresentingAd;
@property (nonatomic, assign) BOOL hasShownCurrentShow;
@property (nonatomic, assign) BOOL hasC2SCachedAd;
@property (nonatomic, assign) BOOL isDestroyed;
@property (nonatomic, assign) NSUInteger loadToken;

@end

@implementation ADMTradPlusInterstitialAdapter

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
    [self showInterstitialFromViewController:rootViewController];
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
    if (self.hasC2SCachedAd && self.interstitialAd != nil && [self.interstitialAd isReady]) {
        self.hasC2SCachedAd = NO;
        self.customAdObj = self.interstitialAd;
        if (self.biddingNotice && !self.biddingNotice.hasNotified) {
            [self notifyBidWinWithPrice:self.biddingNotice.bidPriceCents secondPrice:0];
        }
        double ecpmCents = [ADMTradPlusUtils parseECPMCentsFromString:[self.interstitialAd getECPMLevel]];
        NSDictionary *asset = @{
            @"interstitialAd": self.interstitialAd,
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
    static NSMutableSet<ADMTradPlusInterstitialAdapter *> *activeBidders = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        activeBidders = [NSMutableSet set];
    });

    ADMTradPlusInterstitialAdapter *adapter = [[self alloc] initWithServerExtra:serverExtra localExtra:localExtra];
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
                                           description:@"Missing placement_id / slot_id for Interstitial Ad"];
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
            ADMInterstitialAd *ad = [[ADMInterstitialAd alloc] init];
            ad.adUnitTag = placementID;
            ad.delegate = strongSelf;
            ad.fullScreenContentDelegate = strongSelf;
            ad.request = [ADMTradPlusUtils requestFromServerExtra:strongSelf.serverExtra
                                                       localExtra:strongSelf.localExtra];
            strongSelf.interstitialAd = ad;
            strongSelf.customAdObj = ad;
            [ad load];
        }];
    }];
}

- (BOOL)isAdReady {
    return self.isPresentingAd || (self.interstitialAd != nil && [self.interstitialAd isReady]);
}

- (void)showInterstitialFromViewController:(UIViewController *)viewController {
    if (self.interstitialAd == nil || ![self.interstitialAd isReady]) {
        NSError *err = [ADMTradPlusUtils errorWithCode:ADMTradPlusErrorCodeAdNotReady
                                           description:@"Interstitial ad is not ready for presentation"];
        [self AdShowFailWithError:err];
        if ([self.delegate respondsToSelector:@selector(tradPlusAdapterDidFailToShow:error:)]) {
            [self.delegate tradPlusAdapterDidFailToShow:self error:err];
        }
        return;
    }

    self.isPresentingAd = YES;
    self.hasShownCurrentShow = NO;
    self.isAdReady = YES;
    if (self.biddingNotice && !self.biddingNotice.hasNotified) {
        [self.biddingNotice handleTradPlusWinInfo:nil];
    }
    [ADMTradPlusUtils dispatchOnMainThread:^{
        if (viewController) {
            [self.interstitialAd presentFromViewController:viewController];
        } else {
            [self.interstitialAd presentFromRootViewController];
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
        self.interstitialAd.delegate = nil;
        self.interstitialAd.fullScreenContentDelegate = nil;
        self.interstitialAd = nil;
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

#pragma mark - ADMInterstitialDelegate

- (void)interstitialAdDidReceiveAd:(ADMInterstitialAd *)ad {
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
                                               description:@"Interstitial C2S bidding returned invalid eCPM (<= 0)"];
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
        @"interstitialAd": ad,
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

- (void)interstitialAd:(ADMInterstitialAd *)ad didFailToReceiveAdWithError:(NSError *)error {
    NSError *wrapped = [ADMTradPlusUtils errorFromADMError:error
                                               defaultCode:ADMTradPlusErrorCodeAdLoadFailed
                                        defaultDescription:@"Interstitial ad failed to receive"];
    [self handleFailureWithError:wrapped];
}

- (void)interstitialAd:(ADMInterstitialAd *)ad didFailToLoadWithError:(NSError *)error {
    NSError *wrapped = [ADMTradPlusUtils errorFromADMError:error
                                               defaultCode:ADMTradPlusErrorCodeAdLoadFailed
                                        defaultDescription:@"Interstitial ad failed to load"];
    [self handleFailureWithError:wrapped];
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
    self.isPresentingAd = NO;
    self.hasShownCurrentShow = NO;
    self.isAdReady = NO;
    NSError *wrapped = [ADMTradPlusUtils errorFromADMError:error
                                               defaultCode:ADMTradPlusErrorCodeAdPresentFailed
                                        defaultDescription:@"Interstitial ad failed to present"];
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
                                                       description:@"Interstitial ad load failed"];
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

@implementation TradPlusAdMasterInterstitialAdapter
@end
