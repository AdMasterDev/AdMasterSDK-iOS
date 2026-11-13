//
//  ADMTradPlusUtils.h
//  TradPlusMediationAdMaster
//
//  Parameter extraction, ADMRequest construction, error mapping, and main-thread
//  dispatch helpers for AdMaster TradPlus Custom Adapter.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ADMTradPlusCompat.h"
#import "ADMTradPlusConstants.h"

#if __has_include(<AdMasterSDK/AdMasterSDK.h>)
#import <AdMasterSDK/AdMasterSDK.h>
#else
#import "ADMRequest.h"
#import "ADMSetting.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface ADMTradPlusUtils : NSObject

/// Dispatch block on main thread safely (executes synchronously if already on main thread)
+ (void)dispatchOnMainThread:(dispatch_block_t)block;

/// Top-most active UIViewController for presenting full-screen ads when rootViewController is nil
+ (nullable UIViewController *)topMostViewControllerFrom:(nullable UIViewController *)candidate;

/// Key-window lookup compatible with iOS 13+ UIScene
+ (nullable UIWindow *)activeKeyWindow;

/// Extract serverExtra dictionary from TradPlusAdWaterfallItem
+ (NSDictionary *)serverExtraFromWaterfallItem:(nullable TradPlusAdWaterfallItem *)item;

/// Extract localExtra dictionary from TradPlusAdWaterfallItem
+ (NSDictionary *)localExtraFromWaterfallItem:(nullable TradPlusAdWaterfallItem *)item;

/// Extract AppID from serverExtra / localExtra (supports custom_ext unicode JSON)
+ (nullable NSString *)appIDFromServerExtra:(nullable NSDictionary *)serverExtra
                                 localExtra:(nullable NSDictionary *)localExtra;

/// Extract PlacementID / AdUnitID from serverExtra / localExtra
+ (nullable NSString *)placementIDFromServerExtra:(nullable NSDictionary *)serverExtra
                                       localExtra:(nullable NSDictionary *)localExtra;

/// Extract BidFloor (in cents) from serverExtra / localExtra
+ (int)bidFloorFromServerExtra:(nullable NSDictionary *)serverExtra
                    localExtra:(nullable NSDictionary *)localExtra;

/// Extract AdSize (width, height) from serverExtra / localExtra with fallback defaultSize
+ (CGSize)adSizeFromServerExtra:(nullable NSDictionary *)serverExtra
                     localExtra:(nullable NSDictionary *)localExtra
                    defaultSize:(CGSize)defaultSize;

/// Extract Rewarded Video user_id from serverExtra / localExtra
+ (nullable NSString *)userIDFromServerExtra:(nullable NSDictionary *)serverExtra
                                  localExtra:(nullable NSDictionary *)localExtra;

/// Extract Rewarded Video custom_data / extra_info from serverExtra / localExtra
+ (nullable NSString *)customDataFromServerExtra:(nullable NSDictionary *)serverExtra
                                      localExtra:(nullable NSDictionary *)localExtra;

/// Apply test/debug/HTTPS runtime settings onto ADMSetting
+ (void)updateAdMasterRuntimeFromServerExtra:(nullable NSDictionary *)serverExtra
                                  localExtra:(nullable NSDictionary *)localExtra;

/// Build ADMRequest with bidFloor and extraParams populated
+ (ADMRequest *)requestFromServerExtra:(nullable NSDictionary *)serverExtra
                            localExtra:(nullable NSDictionary *)localExtra;

/// Parse ECPM in cents from AdMaster getECPMLevel string
+ (double)parseECPMCentsFromString:(nullable NSString *)ecpmString;

/// Format ECPM cents into clean string (e.g. "150" or "150.5")
+ (NSString *)formatECPMStringFromCents:(double)ecpmCents;

/// Format ECPM cents into Yuan string (e.g. 150 cents -> "1.50")
+ (NSString *)parseECPMYuanStringFromCents:(double)ecpmCents;

/// Construct standardized NSError in ADMTradPlusErrorDomain
+ (NSError *)errorWithCode:(ADMTradPlusErrorCode)code
               description:(nullable NSString *)description;

/// Wrap an AdMaster SDK NSError into ADMTradPlusErrorDomain
+ (NSError *)errorFromADMError:(nullable NSError *)admError
                   defaultCode:(ADMTradPlusErrorCode)defaultCode
            defaultDescription:(NSString *)defaultDescription;

/// Classify raw AdMaster error code into ADMTradPlusErrorCode
+ (ADMTradPlusErrorCode)classifyADMErrorCode:(NSInteger)admCode
                                 defaultCode:(ADMTradPlusErrorCode)defaultCode;

/// Handle TradPlus extraActWithEvent:info: C2S & Loss/Win events uniformly across all adapters
+ (BOOL)handleAdapterExtraEvent:(NSString *)event
                           info:(nullable NSDictionary *)info
                     forAdapter:(TradPlusBaseAdapter *)adapter;

@end

NS_ASSUME_NONNULL_END
