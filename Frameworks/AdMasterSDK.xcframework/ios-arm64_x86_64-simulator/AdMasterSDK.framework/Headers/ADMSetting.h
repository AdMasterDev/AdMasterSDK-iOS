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
 * 是否测试模式，默认关闭
 * ⚠️仅测试使用，Release版本请确保不调用，否则将无法计费
 */
@property (nonatomic, assign) BOOL isTest;

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

/**
 * 从UserDefault读取CMP写入的GDPR同意相关信息
 */
- (NSDictionary *)getGDPRInformation;

@end

#endif /* ADMSetting_h */
