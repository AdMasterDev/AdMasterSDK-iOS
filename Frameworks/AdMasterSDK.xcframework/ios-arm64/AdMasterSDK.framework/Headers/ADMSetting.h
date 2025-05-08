//
//  ADMSetting
//
//
//
#import <UIKit/UIKit.h>
#import <AdMasterSDK/ADMCommonConfig.h>

@interface ADMSetting : NSObject

@property (nonatomic, assign) BOOL trackCrash;

+ (ADMSetting *)sharedInstance;

/**
 * 设置视频缓存阀值，单位M, 取值范围15M-100M,默认70M
 */
+ (void)setMaxVideoCacheCapacityMb:(NSInteger)capacity;

/**
 关闭SDK 打印日志开关

 @param debugLogEnable YES开启  默认YES
 */
- (void)setDebugLogEnable:(BOOL)debugLogEnable;

/**
 * 限制个性化广告
 * @param limit YES限制，默认NO
 */
- (void)setLimitPersonalAds:(BOOL)limit;

/**
 * 获取个性化广告限制状态，默认不限制
 */
- (BOOL)getLimitPersonalAds;

/**
 * 获取SDK Version
 */
- (NSString *)getSDKVersion;


@end

