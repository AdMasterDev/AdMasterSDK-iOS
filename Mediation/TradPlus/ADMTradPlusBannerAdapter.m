//
//  ADMTradPlusBannerAdapter.m
//  TradPlusMediationAdMaster
//

#import "ADMTradPlusBannerAdapter.h"
#import "ADMTradPlusConstants.h"
#import "ADMTradPlusSDKInitManager.h"
#import "ADMTradPlusUtils.h"

@interface ADMTradPlusBannerAdapter ()

@property (nonatomic, strong, readwrite, nullable) ADMBannerView *bannerView;
@property (nonatomic, strong, readwrite, nullable) ADMTradPlusBiddingNotice *biddingNotice;
@property (nonatomic, copy, readwrite, nullable) NSDictionary *serverExtra;
@property (nonatomic, copy, readwrite, nullable) NSDictionary *localExtra;
@property (nonatomic, copy, nullable) TPAdLoadCompletionBlock loadCompletion;
@property (nonatomic, copy, nullable) TPBiddingCompletionBlock biddingCompletion;
@property (nonatomic, assign) BOOL isBiddingRequest;
@property (nonatomic, assign) BOOL isBannerLoaded;
@property (nonatomic, assign) BOOL hasC2SCachedAd;
@property (nonatomic, assign) BOOL isDestroyed;
@property (nonatomic, assign) NSUInteger loadToken;

@end

@implementation ADMTradPlusBannerAdapter

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

- (void)bannerDidAddSubView:(UIView *)subView {
    if (self.biddingNotice && !self.biddingNotice.hasNotified) {
        [self.biddingNotice handleTradPlusWinInfo:nil];
    }
#if ADM_TRADPLUS_HAS_SDK
    if (self.bannerView && subView) {
        [self setBannerCenterWithBanner:self.bannerView subView:subView];
    }
#else
    if (self.bannerView && subView && self.bannerView.superview != subView) {
        [subView addSubview:self.bannerView];
        self.bannerView.center = CGPointMake(CGRectGetMidX(subView.bounds), CGRectGetMidY(subView.bounds));
    }
#endif
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

    // C2S Cached Ad Reuse: if C2S bidding already loaded a valid banner on this instance, reuse it immediately
    if (self.hasC2SCachedAd && self.bannerView != nil && (self.isBannerLoaded || [self.bannerView isReady])) {
        self.hasC2SCachedAd = NO;
        self.isBannerLoaded = YES;
        self.customAdObj = self.bannerView;
        if (self.biddingNotice && !self.biddingNotice.hasNotified) {
            [self notifyBidWinWithPrice:self.biddingNotice.bidPriceCents secondPrice:0];
        }
        double ecpmCents = [ADMTradPlusUtils parseECPMCentsFromString:[self.bannerView getECPMLevel]];
        NSDictionary *asset = @{
            @"adView": self.bannerView,
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

    self.isBannerLoaded = NO;
    [self performLoadOrBidding];
}

- (void)startBiddingRequestWithInfo:(NSDictionary *)serverExtra
                          localInfo:(NSDictionary *)localExtra
                         completion:(TPBiddingCompletionBlock)completion {
    self.serverExtra = serverExtra;
    self.localExtra = localExtra;
    self.biddingCompletion = completion;
    self.isBiddingRequest = YES;
    self.isBannerLoaded = NO;
    self.hasC2SCachedAd = NO;
    [self performLoadOrBidding];
}

+ (void)startBiddingRequestWithInfo:(NSDictionary *)serverExtra
                          localInfo:(NSDictionary *)localExtra
                         completion:(TPBiddingCompletionBlock)completion {
    static NSMutableSet<ADMTradPlusBannerAdapter *> *activeBidders = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        activeBidders = [NSMutableSet set];
    });

    ADMTradPlusBannerAdapter *adapter = [[self alloc] initWithServerExtra:serverExtra localExtra:localExtra];
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
                                           description:@"Missing placement_id / slot_id for Banner Ad"];
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
            CGSize bannerSize = [ADMTradPlusUtils adSizeFromServerExtra:strongSelf.serverExtra
                                                             localExtra:strongSelf.localExtra
                                                            defaultSize:CGSizeMake(320.0, 50.0)];
            ADMBannerView *banner = [[ADMBannerView alloc] initWithAdSize:bannerSize adUnitTag:placementID];
            banner.delegate = strongSelf;
            banner.request = [ADMTradPlusUtils requestFromServerExtra:strongSelf.serverExtra
                                                           localExtra:strongSelf.localExtra];
            strongSelf.bannerView = banner;
            strongSelf.customAdObj = banner;
            [banner loadAd];
        }];
    }];
}

- (BOOL)isAdReady {
    return self.bannerView != nil && (self.isBannerLoaded || [self.bannerView isReady]);
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
        self.bannerView.delegate = nil;
        [self.bannerView removeFromSuperview];
        self.bannerView = nil;
        self.customAdObj = nil;
        self.biddingNotice = nil;
        self.loadCompletion = nil;
        self.biddingCompletion = nil;
        self.isBannerLoaded = NO;
        self.isAdReady = NO;
        self.hasC2SCachedAd = NO;
    }];
}

- (void)destory {
    [self destroy];
}

#pragma mark - ADMBannerDelegate

- (void)bannerViewDidReceiveAd:(ADMBannerView *)bannerView {
    self.isBannerLoaded = YES;
    self.customAdObj = bannerView;
    NSString *placementID = [ADMTradPlusUtils placementIDFromServerExtra:self.serverExtra localExtra:self.localExtra] ?: @"";
    double ecpmCents = [ADMTradPlusUtils parseECPMCentsFromString:[bannerView getECPMLevel]];

    self.biddingNotice = [[ADMTradPlusBiddingNotice alloc] initWithPlacementID:placementID
                                                                        unitID:placementID
                                                                 bidPriceCents:ecpmCents
                                                                      adObject:bannerView];

    if (self.isBiddingRequest) {
        if (ecpmCents <= 0.0) {
            NSError *err = [ADMTradPlusUtils errorWithCode:ADMTradPlusErrorCodeBiddingFailed
                                               description:@"Banner C2S bidding returned invalid eCPM (<= 0)"];
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
                                                     customObject:bannerView
                                                    biddingNotice:self.biddingNotice];
        if (self.biddingCompletion) {
            TPBiddingCompletionBlock block = self.biddingCompletion;
            self.biddingCompletion = nil;
            block(bidInfo, nil);
        }
        return;
    }

    NSDictionary *asset = @{
        @"adView": bannerView,
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

- (void)bannerView:(ADMBannerView *)bannerView didFailToReceiveAdWithError:(NSError *)error {
    NSError *wrapped = [ADMTradPlusUtils errorFromADMError:error
                                               defaultCode:ADMTradPlusErrorCodeAdLoadFailed
                                        defaultDescription:@"Banner ad failed to load"];
    [self handleFailureWithError:wrapped];
}

- (void)bannerViewDidRecordImpression:(ADMBannerView *)bannerView {
    self.isBannerLoaded = YES;
    self.isAdReady = YES;
    [self AdShow];
    if ([self.delegate respondsToSelector:@selector(tradPlusAdapterDidShow:extra:)]) {
        [self.delegate tradPlusAdapterDidShow:self extra:nil];
    }
}

- (void)bannerView:(ADMBannerView *)bannerView didFailToDisplayAdWithError:(NSError *)error {
    NSError *wrapped = [ADMTradPlusUtils errorFromADMError:error
                                               defaultCode:ADMTradPlusErrorCodeAdPresentFailed
                                        defaultDescription:@"Banner ad failed to display"];
    [self AdShowFailWithError:wrapped];
    if ([self.delegate respondsToSelector:@selector(tradPlusAdapterDidFailToShow:error:)]) {
        [self.delegate tradPlusAdapterDidFailToShow:self error:wrapped];
    }
}

- (void)bannerViewDidRecordClick:(ADMBannerView *)bannerView {
    self.isBannerLoaded = YES;
    self.isAdReady = YES;
    [self AdClick];
    if ([self.delegate respondsToSelector:@selector(tradPlusAdapterDidClick:extra:)]) {
        [self.delegate tradPlusAdapterDidClick:self extra:nil];
    }
}

- (void)bannerViewDidDismiss:(ADMBannerView *)bannerView {
    self.isBannerLoaded = YES;
    self.isAdReady = YES;
    [self AdClose];
    if ([self.delegate respondsToSelector:@selector(tradPlusAdapterDidClose:extra:)]) {
        [self.delegate tradPlusAdapterDidClose:self extra:nil];
    }
}

#pragma mark - Private

- (void)handleFailureWithError:(NSError *)error {
    self.isBannerLoaded = NO;
    self.hasC2SCachedAd = NO;
    NSError *finalError = error ?: [ADMTradPlusUtils errorWithCode:ADMTradPlusErrorCodeAdLoadFailed
                                                       description:@"Banner ad load failed"];
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

@implementation TradPlusAdMasterBannerAdapter
@end
