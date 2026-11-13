//
//  ADMTradPlusSDKInitManager.h
//  TradPlusMediationAdMaster
//
//  Thread-safe singleton managing AdMaster SDK initialization for TradPlus Custom Adapters.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^ADMTradPlusInitCompletion)(BOOL success, NSError *_Nullable error);

@interface ADMTradPlusSDKInitManager : NSObject

@property (nonatomic, assign, readonly) BOOL isInitialized;
@property (nonatomic, copy, readonly, nullable) NSString *initializedAppID;

+ (instancetype)sharedInstance;

/// Initialize AdMaster SDK with parameters extracted from serverExtra / localExtra
- (void)initializeSDKWithServerExtra:(nullable NSDictionary *)serverExtra
                          localExtra:(nullable NSDictionary *)localExtra
                          completion:(ADMTradPlusInitCompletion)completion;

/// Initialize AdMaster SDK directly with an explicit App ID
- (void)initializeSDKWithAppID:(nullable NSString *)appID
                   serverExtra:(nullable NSDictionary *)serverExtra
                    localExtra:(nullable NSDictionary *)localExtra
                    completion:(ADMTradPlusInitCompletion)completion;

/// Reset state for unit testing
- (void)resetForTesting;

@end

NS_ASSUME_NONNULL_END
