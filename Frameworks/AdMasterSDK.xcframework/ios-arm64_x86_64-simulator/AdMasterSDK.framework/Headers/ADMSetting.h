//
//  ADMSetting
//
//
//
#ifndef ADMSetting_h
#define ADMSetting_h

#import <UIKit/UIKit.h>
#import <AdMasterSDK/ADMCommonConfig.h>

@interface ADMSetting : NSObject

/**
 * Test mode. Default NO.
 * Marks requests as test traffic on the real bidding path.
 * For testing only. Do not enable in release builds.
 */
@property (nonatomic, assign) BOOL isTest;

/**
 * Mock mode. Default NO.
 * Returns fixed test ads without bidding or billing.
 * For integration testing only. Do not enable in release builds.
 */
@property (nonatomic, assign) BOOL isMock;

@property (nonatomic, assign) BOOL trackCrash;

+ (ADMSetting *)sharedInstance;

/**
 * Max video cache size in MB. Range 15–100, default 70.
 */
+ (void)setMaxVideoCacheCapacityMb:(NSInteger)capacity;

/**
 * Enable or disable SDK debug logs.
 * Debug logs are disabled by default and should be enabled only while testing.
 * @param debugLogEnable YES to enable (default NO).
 */
- (void)setDebugLogEnable:(BOOL)debugLogEnable;

/**
 * Limit personalized ads.
 * @param limit YES to limit (default NO).
 */
- (void)setLimitPersonalAds:(BOOL)limit;

/**
 * Whether personalized ads are limited (default not limited).
 */
- (BOOL)getLimitPersonalAds;

/**
 * SDK version string.
 */
- (NSString *)getSDKVersion;

/**
 * GDPR consent info written by CMP to NSUserDefaults.
 */
- (NSDictionary *)getGDPRInformation;

@end

#endif /* ADMSetting_h */
