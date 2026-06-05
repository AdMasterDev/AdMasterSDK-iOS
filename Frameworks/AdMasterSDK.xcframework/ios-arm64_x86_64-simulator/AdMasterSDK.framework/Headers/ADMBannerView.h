//
//  ADMBannerView.h
//  AdMasterSDK
//

#ifndef ADMBannerView_h
#define ADMBannerView_h

#import <UIKit/UIKit.h>
#import <AdMasterSDK/ADMBannerDelegate.h>
#import <AdMasterSDK/ADMRequest.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(BannerView)
@interface ADMBannerView : UIView

- (nonnull instancetype)initWithAdSize:(CGSize)adSize;
- (nonnull instancetype)initWithAdSize:(CGSize)adSize adUnitTag:(nonnull NSString *)adUnitTag;

@property (nonatomic, assign) IBInspectable CGSize adSize;
@property (nonatomic, copy, nullable) IBInspectable NSString *adUnitTag;
@property (nonatomic, weak, nullable) IBOutlet id<ADMBannerDelegate> delegate;
@property (nonatomic, copy) ADMRequest *request;

- (void)loadAd;
- (BOOL)isReady;

- (nullable NSString *)getBiddingToken;
- (void)loadBiddingAdWithTokenId:(NSString *)tokenId;
- (void)loadBiddingAdWithADMData:(NSString *)admData;
- (nullable NSString *)getECPMLevel;
- (nullable NSString *)getPECPM;
- (nullable NSString *)getAdDataForKey:(NSString *)key;

- (void)biddingSuccessWithSecondInfo:(NSDictionary *)secondInfo
                          completion:(nullable void (^)(BOOL success, NSString * _Nullable errorInfo))completion;
- (void)biddingFailWithWinInfo:(NSDictionary *)winInfo
                    completion:(nullable void (^)(BOOL success, NSString * _Nullable errorInfo))completion;

@end

NS_ASSUME_NONNULL_END

#endif /* ADMBannerView_h */
