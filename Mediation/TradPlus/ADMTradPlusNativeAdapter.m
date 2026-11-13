//
//  ADMTradPlusNativeAdapter.m
//  TradPlusMediationAdMaster
//

#import "ADMTradPlusNativeAdapter.h"
#import "ADMTradPlusConstants.h"
#import "ADMTradPlusSDKInitManager.h"
#import "ADMTradPlusUtils.h"

@interface ADMTradPlusNativeAdapter ()

@property (nonatomic, strong, readwrite, nullable) ADMNativeAdLoader *nativeAdLoader;
@property (nonatomic, strong, readwrite, nullable) NSArray<ADMTradPlusNativeAd *> *nativeAds;
@property (nonatomic, strong, readwrite, nullable) ADMTradPlusBiddingNotice *biddingNotice;
@property (nonatomic, copy, readwrite, nullable) NSDictionary *serverExtra;
@property (nonatomic, copy, readwrite, nullable) NSDictionary *localExtra;
@property (nonatomic, copy, nullable) TPAdLoadCompletionBlock loadCompletion;
@property (nonatomic, copy, nullable) TPBiddingCompletionBlock biddingCompletion;
@property (nonatomic, assign) BOOL isBiddingRequest;
@property (nonatomic, assign) BOOL hasC2SCachedAd;
@property (nonatomic, assign) BOOL isDestroyed;
@property (nonatomic, assign) NSUInteger loadToken;

@end

@implementation ADMTradPlusNativeAdapter

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

- (void)biddingSuccessWithSecondInfo:(NSDictionary *)info {
    [super biddingSuccessWithSecondInfo:info];
    [self.biddingNotice handleTradPlusWinInfo:info];
}

- (void)biddingFailWithWinInfo:(NSDictionary *)info {
    [super biddingFailWithWinInfo:info];
    [self.biddingNotice handleTradPlusLossInfo:info];
    [self destroy];
}

#if ADM_TRADPLUS_HAS_SDK
- (void)populateWaterfallItemAdResWithNativeAd:(ADMTradPlusNativeAd *)nativeAd {
    if (!self.waterfallItem || !nativeAd) {
        return;
    }
    TradPlusAdRes *res = [[TradPlusAdRes alloc] init];
    res.adType = TPAdResTypeAssets;
    res.title = nativeAd.title.length > 0 ? nativeAd.title : (nativeAd.advertiserName.length > 0 ? nativeAd.advertiserName : @"Sponsored");
    res.body = nativeAd.mainText;
    res.ctaText = nativeAd.ctaText;
    if (nativeAd.iconImageURLString.length > 0) {
        res.iconImageURL = nativeAd.iconImageURLString;
        if (self.downLoadURLArray && ![self.downLoadURLArray containsObject:nativeAd.iconImageURLString]) {
            [self.downLoadURLArray addObject:nativeAd.iconImageURLString];
        }
    }
    if (nativeAd.mainImageURLString.length > 0) {
        res.mediaImageURL = nativeAd.mainImageURLString;
        if (self.downLoadURLArray && ![self.downLoadURLArray containsObject:nativeAd.mainImageURLString]) {
            [self.downLoadURLArray addObject:nativeAd.mainImageURLString];
        }
    }
    if (nativeAd.advertiserName.length > 0) {
        res.advertiser = nativeAd.advertiserName;
    }
    if (nativeAd.mediaView) {
        res.mediaView = nativeAd.mediaView;
    }
    self.waterfallItem.adRes = res;
}

- (UIView *)buildDrawCardViewForNativeAd:(ADMTradPlusNativeAd *)nativeAd frame:(CGRect)frame {
    BOOL hasValidFrame = CGRectGetWidth(frame) > 0 && CGRectGetHeight(frame) > 0;
    CGRect targetFrame = hasValidFrame ? frame : CGRectMake(0, 0, 320, 96);
    UIView *card = [[UIView alloc] initWithFrame:targetFrame];
    card.backgroundColor = [UIColor colorWithRed:0.12 green:0.14 blue:0.18 alpha:1.0];
    card.layer.cornerRadius = 8.0;
    card.clipsToBounds = YES;

    UIView *mediaContainer = [[UIView alloc] initWithFrame:CGRectMake(8, 8, 80, CGRectGetHeight(targetFrame) - 16)];
    mediaContainer.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    mediaContainer.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    mediaContainer.layer.cornerRadius = 6.0;
    mediaContainer.clipsToBounds = YES;

    UIImageView *posterImageView = [[UIImageView alloc] initWithFrame:mediaContainer.bounds];
    posterImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    posterImageView.contentMode = UIViewContentModeScaleAspectFill;
    posterImageView.clipsToBounds = YES;
    if (self.waterfallItem.adRes.mediaImage) {
        posterImageView.image = self.waterfallItem.adRes.mediaImage;
    } else if (nativeAd.mainImageURLString.length > 0) {
        NSURL *imgURL = [NSURL URLWithString:nativeAd.mainImageURLString];
        if (imgURL) {
            [[[NSURLSession sharedSession] dataTaskWithURL:imgURL completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
                if (data.length > 0) {
                    UIImage *img = [UIImage imageWithData:data];
                    if (img) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            posterImageView.image = img;
                        });
                    }
                }
            }] resume];
        }
    }
    [mediaContainer addSubview:posterImageView];

    if (nativeAd.mediaView) {
        nativeAd.mediaView.frame = mediaContainer.bounds;
        nativeAd.mediaView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        nativeAd.mediaView.clipsToBounds = YES;
        [mediaContainer addSubview:nativeAd.mediaView];
    }
    [card addSubview:mediaContainer];

    BOOL hasIcon = (self.waterfallItem.adRes.iconImage != nil || nativeAd.iconImageURLString.length > 0);
    CGFloat titleX = hasIcon ? 120.0 : 96.0;
    if (hasIcon) {
        UIImageView *iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(96, 10, 20, 20)];
        iconImageView.contentMode = UIViewContentModeScaleAspectFill;
        iconImageView.layer.cornerRadius = 4.0;
        iconImageView.clipsToBounds = YES;
        if (self.waterfallItem.adRes.iconImage) {
            iconImageView.image = self.waterfallItem.adRes.iconImage;
        } else if (nativeAd.iconImageURLString.length > 0) {
            NSURL *iconURL = [NSURL URLWithString:nativeAd.iconImageURLString];
            if (iconURL) {
                [[[NSURLSession sharedSession] dataTaskWithURL:iconURL completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
                    if (data.length > 0) {
                        UIImage *img = [UIImage imageWithData:data];
                        if (img) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                iconImageView.image = img;
                            });
                        }
                    }
                }] resume];
            }
        }
        [card addSubview:iconImageView];
    }

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(titleX, 10, CGRectGetWidth(targetFrame) - titleX - 84, 20)];
    titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    titleLabel.font = [UIFont boldSystemFontOfSize:13];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.text = nativeAd.title ?: @"AdMaster Draw Ad";
    [card addSubview:titleLabel];

    UILabel *descLabel = [[UILabel alloc] initWithFrame:CGRectMake(96, 34, CGRectGetWidth(targetFrame) - 180, 36)];
    descLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    descLabel.font = [UIFont systemFontOfSize:11];
    descLabel.textColor = [UIColor colorWithWhite:0.85 alpha:1.0];
    descLabel.numberOfLines = 2;
    descLabel.text = nativeAd.mainText ?: @"Draw feed native video / image ad";
    [card addSubview:descLabel];

    UILabel *ctaLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetWidth(targetFrame) - 76, (CGRectGetHeight(targetFrame) - 28) / 2.0, 68, 28)];
    ctaLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    ctaLabel.backgroundColor = [UIColor colorWithRed:0.15 green:0.55 blue:0.95 alpha:1.0];
    ctaLabel.textColor = [UIColor whiteColor];
    ctaLabel.font = [UIFont boldSystemFontOfSize:11];
    ctaLabel.textAlignment = NSTextAlignmentCenter;
    ctaLabel.layer.cornerRadius = 6.0;
    ctaLabel.clipsToBounds = YES;
    ctaLabel.text = nativeAd.ctaText.length > 0 ? nativeAd.ctaText : @"查看详情";
    [card addSubview:ctaLabel];

    if (self.biddingNotice && !self.biddingNotice.hasNotified) {
        [self.biddingNotice handleTradPlusWinInfo:nil];
    }
    [nativeAd registerContainer:card withClickableViews:@[card, mediaContainer, titleLabel, descLabel, ctaLabel] viewController:self.rootViewController];
    return card;
}

- (NSArray<UIView *> *)getDrawList {
    if (self.nativeAds.count == 0) {
        return @[];
    }
    NSMutableArray<UIView *> *drawViews = [NSMutableArray arrayWithCapacity:self.nativeAds.count];
    for (ADMTradPlusNativeAd *nativeAd in self.nativeAds) {
        UIView *card = [self buildDrawCardViewForNativeAd:nativeAd frame:CGRectMake(0, 0, 320, 96)];
        if (card) {
            [drawViews addObject:card];
        }
    }
    return [drawViews copy];
}

- (UIView *)drawRender:(UIView *)subView {
    ADMTradPlusNativeAd *firstAd = self.nativeAds.firstObject;
    if (!firstAd) {
        return nil;
    }
    CGRect bounds = subView ? subView.bounds : CGRectMake(0, 0, 320, 96);
    return [self buildDrawCardViewForNativeAd:firstAd frame:bounds];
}

- (UIView *)endRender:(NSDictionary *)viewInfo clickView:(NSArray *)array {
    ADMTradPlusNativeAd *firstAd = self.nativeAds.firstObject;
    if (!firstAd) {
        return nil;
    }
    if (self.biddingNotice && !self.biddingNotice.hasNotified) {
        [self.biddingNotice handleTradPlusWinInfo:nil];
    }
    UIView *adView = nil;
    if (kTPRendererAdView && [viewInfo[kTPRendererAdView] isKindOfClass:[UIView class]]) {
        adView = viewInfo[kTPRendererAdView];
    } else if ([viewInfo[@"adView"] isKindOfClass:[UIView class]]) {
        adView = viewInfo[@"adView"];
    }
    UIView *mediaContainer = nil;
    if (kTPRendererMediaView && [viewInfo[kTPRendererMediaView] isKindOfClass:[UIView class]]) {
        mediaContainer = viewInfo[kTPRendererMediaView];
    } else if ([viewInfo[@"mediaView"] isKindOfClass:[UIView class]]) {
        mediaContainer = viewInfo[@"mediaView"];
    } else if (kTPRendererMainImageView && [viewInfo[kTPRendererMainImageView] isKindOfClass:[UIView class]]) {
        mediaContainer = viewInfo[kTPRendererMainImageView];
    } else if ([viewInfo[@"mainImageView"] isKindOfClass:[UIView class]]) {
        mediaContainer = viewInfo[@"mainImageView"];
    }
    if (firstAd.mediaView && mediaContainer && firstAd.mediaView.superview != mediaContainer) {
        firstAd.mediaView.frame = mediaContainer.bounds;
        firstAd.mediaView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [mediaContainer addSubview:firstAd.mediaView];
    }
    if (mediaContainer) {
        mediaContainer.clipsToBounds = YES;
        for (UIView *sub in mediaContainer.subviews) {
            sub.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            sub.clipsToBounds = YES;
            if (CGRectGetWidth(mediaContainer.bounds) > 0 && CGRectGetHeight(mediaContainer.bounds) > 0) {
                sub.frame = mediaContainer.bounds;
            }
        }
    }
    if (adView) {
        [firstAd registerContainer:adView withClickableViews:array viewController:self.rootViewController];
    }
    return adView;
}

- (void)didAddSubView {
    ADMTradPlusNativeAd *firstAd = self.nativeAds.firstObject;
    if (!firstAd) {
        return;
    }
    void (^syncAndActivate)(void) = ^{
        UIView *adView = firstAd.registeredContainerView;
        if (adView.superview) {
            [adView.superview setNeedsLayout];
            [adView.superview layoutIfNeeded];
            CGRect superBounds = adView.superview.bounds;
            if (CGRectGetWidth(superBounds) > 0 && CGRectGetWidth(adView.frame) <= 0) {
                CGFloat targetH = CGRectGetHeight(adView.frame) > 0 ? CGRectGetHeight(adView.frame) : CGRectGetHeight(superBounds);
                adView.frame = CGRectMake(0, (CGRectGetHeight(superBounds) - targetH) / 2.0, CGRectGetWidth(superBounds), targetH);
            }
        }
        [firstAd activateMediaAndImpressionIfNeeded];
    };
    syncAndActivate();
    dispatch_async(dispatch_get_main_queue(), syncAndActivate);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), syncAndActivate);
}

- (void)templateRender:(UIView *)subView {
    ADMTradPlusNativeAd *firstAd = self.nativeAds.firstObject;
    if (!firstAd || !subView) {
        return;
    }
    if (self.biddingNotice && !self.biddingNotice.hasNotified) {
        [self.biddingNotice handleTradPlusWinInfo:nil];
    }
    UIView *mediaView = firstAd.mediaView;
    if (mediaView) {
        mediaView.frame = subView.bounds;
        mediaView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [subView addSubview:mediaView];
    }
    [firstAd registerContainer:subView withClickableViews:@[subView] viewController:self.rootViewController];
}
#endif

#pragma mark - Direct / Dictionary Entrypoints

- (void)loadADWithInfo:(NSDictionary *)serverExtra
             localInfo:(NSDictionary *)localExtra
            completion:(TPAdLoadCompletionBlock)completion {
    self.serverExtra = serverExtra;
    self.localExtra = localExtra;
    self.loadCompletion = completion;
    self.isBiddingRequest = NO;

    // C2S Cached Ad Reuse
    if (self.hasC2SCachedAd && [self isAdReady]) {
        self.hasC2SCachedAd = NO;
        ADMTradPlusNativeAd *firstNativeAd = self.nativeAds.firstObject;
        self.customAdObj = firstNativeAd;
#if ADM_TRADPLUS_HAS_SDK
        [self populateWaterfallItemAdResWithNativeAd:firstNativeAd];
#endif
        if (self.biddingNotice && !self.biddingNotice.hasNotified) {
            [self notifyBidWinWithPrice:self.biddingNotice.bidPriceCents secondPrice:0];
        }
        NSMutableArray<NSDictionary *> *assets = [NSMutableArray arrayWithCapacity:self.nativeAds.count];
        for (ADMTradPlusNativeAd *nativeAd in self.nativeAds) {
            [assets addObject:[nativeAd toTradPlusAssetDictionary]];
        }
        [self AdLoaded];
        if (self.loadCompletion) {
            TPAdLoadCompletionBlock block = self.loadCompletion;
            self.loadCompletion = nil;
            block([assets copy], nil);
        }
        if ([self.delegate respondsToSelector:@selector(tradPlusAdapterDidLoad:extra:)]) {
            [self.delegate tradPlusAdapterDidLoad:self extra:assets.firstObject];
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
    static NSMutableSet<ADMTradPlusNativeAdapter *> *activeBidders = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        activeBidders = [NSMutableSet set];
    });

    ADMTradPlusNativeAdapter *adapter = [[self alloc] initWithServerExtra:serverExtra localExtra:localExtra];
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
                                           description:@"Missing placement_id / slot_id for Native Ad"];
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
            ADMNativeAdLoader *loader = [[ADMNativeAdLoader alloc] init];
            loader.adUnitTag = placementID;
            loader.delegate = strongSelf;
            loader.request = [ADMTradPlusUtils requestFromServerExtra:strongSelf.serverExtra
                                                           localExtra:strongSelf.localExtra];
            strongSelf.nativeAdLoader = loader;
            [loader load];
        }];
    }];
}

- (BOOL)isAdReady {
    if (self.nativeAds.count == 0) {
        return NO;
    }
    ADMTradPlusNativeAd *firstAd = self.nativeAds.firstObject;
    return firstAd.nativeAdObject != nil && ![firstAd.nativeAdObject isExpired];
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
        self.nativeAdLoader.delegate = nil;
        self.nativeAdLoader = nil;
        for (ADMTradPlusNativeAd *nativeAd in self.nativeAds) {
            [nativeAd destroy];
        }
        self.nativeAds = nil;
        self.customAdObj = nil;
        self.biddingNotice = nil;
        self.loadCompletion = nil;
        self.biddingCompletion = nil;
        self.isAdReady = NO;
        self.hasC2SCachedAd = NO;
    }];
}

- (void)destory {
    [self destroy];
}

#pragma mark - ADMNativeAdLoaderDelegate

- (void)nativeAdLoader:(ADMNativeAdLoader *)nativeAdLoader
   didReceiveNativeAds:(NSArray<ADMNativeAdObject *> *)nativeAdObjects {
    if (nativeAdObjects.count == 0) {
        NSError *err = [ADMTradPlusUtils errorWithCode:ADMTradPlusErrorCodeNoFill
                                           description:@"Native ad loader returned empty ad list"];
        [self handleFailureWithError:err];
        return;
    }

    NSMutableArray<ADMTradPlusNativeAd *> *wrappedAds = [NSMutableArray arrayWithCapacity:nativeAdObjects.count];
    NSMutableArray<NSDictionary *> *assets = [NSMutableArray arrayWithCapacity:nativeAdObjects.count];

    for (ADMNativeAdObject *obj in nativeAdObjects) {
        ADMTradPlusNativeAd *wrapped = [[ADMTradPlusNativeAd alloc] initWithNativeAdObject:obj
                                                                                   adapter:self
                                                                               serverExtra:self.serverExtra
                                                                                localExtra:self.localExtra];
        [wrappedAds addObject:wrapped];
        [assets addObject:[wrapped toTradPlusAssetDictionary]];
    }

    self.nativeAds = [wrappedAds copy];
    ADMTradPlusNativeAd *firstAd = wrappedAds.firstObject;
    self.customAdObj = firstAd;
#if ADM_TRADPLUS_HAS_SDK
    [self populateWaterfallItemAdResWithNativeAd:firstAd];
#endif

    NSString *placementID = [ADMTradPlusUtils placementIDFromServerExtra:self.serverExtra localExtra:self.localExtra] ?: @"";
    double ecpmCents = [firstAd ecpmCents];

    self.biddingNotice = [[ADMTradPlusBiddingNotice alloc] initWithPlacementID:placementID
                                                                        unitID:placementID
                                                                 bidPriceCents:ecpmCents
                                                                      adObject:firstAd.nativeAdObject];

    if (self.isBiddingRequest) {
        if (ecpmCents <= 0.0) {
            NSError *err = [ADMTradPlusUtils errorWithCode:ADMTradPlusErrorCodeBiddingFailed
                                               description:@"Native C2S bidding returned invalid eCPM (<= 0)"];
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
                                                     customObject:firstAd
                                                    biddingNotice:self.biddingNotice];
        if (self.biddingCompletion) {
            TPBiddingCompletionBlock block = self.biddingCompletion;
            self.biddingCompletion = nil;
            block(bidInfo, nil);
        }
        return;
    }

    [self AdLoaded];
    if (self.loadCompletion) {
        TPAdLoadCompletionBlock block = self.loadCompletion;
        self.loadCompletion = nil;
        block([assets copy], nil);
    }
    if ([self.delegate respondsToSelector:@selector(tradPlusAdapterDidLoad:extra:)]) {
        [self.delegate tradPlusAdapterDidLoad:self extra:assets.firstObject];
    }
}

- (void)nativeAdLoader:(ADMNativeAdLoader *)nativeAdLoader
didFailToReceiveAdWithError:(NSError *)error
        nativeAdObject:(ADMNativeAdObject *)nativeAdObject {
    NSError *wrapped = [ADMTradPlusUtils errorFromADMError:error
                                               defaultCode:ADMTradPlusErrorCodeAdLoadFailed
                                        defaultDescription:@"Native ad failed to load"];
    [self handleFailureWithError:wrapped];
}

#pragma mark - Internal Callbacks from ADMTradPlusNativeAd

- (void)notifyNativeAdDidShow:(ADMTradPlusNativeAd *)nativeAd {
    self.isAdReady = YES;
    [self AdShow];
    if ([self.delegate respondsToSelector:@selector(tradPlusAdapterDidShow:extra:)]) {
        [self.delegate tradPlusAdapterDidShow:self extra:[nativeAd toTradPlusAssetDictionary]];
    }
}

- (void)notifyNativeAdDidClick:(ADMTradPlusNativeAd *)nativeAd {
    self.isAdReady = YES;
    [self AdClick];
    if ([self.delegate respondsToSelector:@selector(tradPlusAdapterDidClick:extra:)]) {
        [self.delegate tradPlusAdapterDidClick:self extra:[nativeAd toTradPlusAssetDictionary]];
    }
}

- (void)notifyNativeAdDidClose:(ADMTradPlusNativeAd *)nativeAd {
    self.isAdReady = YES;
    [self AdClose];
    if ([self.delegate respondsToSelector:@selector(tradPlusAdapterDidClose:extra:)]) {
        [self.delegate tradPlusAdapterDidClose:self extra:[nativeAd toTradPlusAssetDictionary]];
    }
}

- (void)notifyNativeAdVideoDidStart:(ADMTradPlusNativeAd *)nativeAd {
    self.isAdReady = YES;
    [self AdVideoStart];
    if ([self.delegate respondsToSelector:@selector(tradPlusAdapterVideoDidStart:extra:)]) {
        [self.delegate tradPlusAdapterVideoDidStart:self extra:[nativeAd toTradPlusAssetDictionary]];
    }
}

- (void)notifyNativeAdVideoDidEnd:(ADMTradPlusNativeAd *)nativeAd {
    self.isAdReady = YES;
    [self AdVideoEnd];
    if ([self.delegate respondsToSelector:@selector(tradPlusAdapterVideoDidEnd:extra:)]) {
        [self.delegate tradPlusAdapterVideoDidEnd:self extra:[nativeAd toTradPlusAssetDictionary]];
    }
}

#pragma mark - Private

- (void)handleFailureWithError:(NSError *)error {
    self.hasC2SCachedAd = NO;
    NSError *finalError = error ?: [ADMTradPlusUtils errorWithCode:ADMTradPlusErrorCodeAdLoadFailed
                                                       description:@"Native ad load failed"];
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

@implementation TradPlusAdMasterNativeAdapter
@end
