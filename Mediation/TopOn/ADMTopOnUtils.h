#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "ADMTopOnConstants.h"
#import "ADMTopOnAnyThinkCompat.h"

@class ADMRequest;
@class ADMError;

NS_ASSUME_NONNULL_BEGIN

/**
 * TopOn 聚合适配器参数提取、环境同步与通用工具类
 * 对标 Android: cc.admaster.android.topon.adapter.AdMasterTopOnParamExtractor
 */
@interface ADMTopOnUtils : NSObject

/// 合并 serverExtra、localExtra 并解析 custom_ext JSON（支持 \uXXXX 反转义）后的扁平参数字典
+ (NSDictionary<NSString *, id> *)mergedParametersWithServerExtra:(nullable NSDictionary *)serverExtra
                                                       localExtra:(nullable NSDictionary *)localExtra;

/// 提取 AppID (app_id)
+ (nullable NSString *)appIDFromServerExtra:(nullable NSDictionary *)serverExtra
                                 localExtra:(nullable NSDictionary *)localExtra;

/// 提取广告位 ID（按 placement_id -> ad_unit_id -> slot_id 优先级回退）
+ (nullable NSString *)placementIDFromServerExtra:(nullable NSDictionary *)serverExtra
                                       localExtra:(nullable NSDictionary *)localExtra;

/// 提取 TopOn unit_id（用于构造 ATBidInfo）
+ (NSString *)unitIDFromServerExtra:(nullable NSDictionary *)serverExtra
                         localExtra:(nullable NSDictionary *)localExtra;

/// 提取竞价底价（单位：分，未配置或 <= 0 时返回 0）
+ (int)bidFloorFromServerExtra:(nullable NSDictionary *)serverExtra
                    localExtra:(nullable NSDictionary *)localExtra;

/// 提取是否开启测试模式
+ (BOOL)isTestModeFromServerExtra:(nullable NSDictionary *)serverExtra
                       localExtra:(nullable NSDictionary *)localExtra;

/// 提取是否开启 Mock 模式
+ (BOOL)isMockModeFromServerExtra:(nullable NSDictionary *)serverExtra
                       localExtra:(nullable NSDictionary *)localExtra;

/// 提取 Banner/开屏尺寸（默认 defaultSize）
+ (CGSize)adSizeFromServerExtra:(nullable NSDictionary *)serverExtra
                     localExtra:(nullable NSDictionary *)localExtra
                    defaultSize:(CGSize)defaultSize;

/// 提取激励视频 user_id
+ (nullable NSString *)userIDFromServerExtra:(nullable NSDictionary *)serverExtra
                                  localExtra:(nullable NSDictionary *)localExtra;

/// 提取激励视频 custom_data / extraInfo
+ (nullable NSString *)customDataFromServerExtra:(nullable NSDictionary *)serverExtra
                                      localExtra:(nullable NSDictionary *)localExtra;

/// 同步 test / mock 开关到 ADMSetting.sharedInstance
+ (void)updateAdMasterRuntimeFromServerExtra:(nullable NSDictionary *)serverExtra
                                  localExtra:(nullable NSDictionary *)localExtra;

/// 根据 serverExtra 和 localExtra 构造 ADMRequest（含 bidFloor）
+ (ADMRequest *)requestFromServerExtra:(nullable NSDictionary *)serverExtra
                            localExtra:(nullable NSDictionary *)localExtra;

/// 解析 getECPMLevel 返回的分值字符串为非负浮点数（单位：分），非法或空值返回 0.0
+ (double)parseECPMCentsFromString:(nullable NSString *)ecpmString;

/// 构造 TopOn 适配器标准 NSError
+ (NSError *)errorWithCode:(ADMTopOnErrorCode)code description:(NSString *)description;

/// 将 ADMError 转换为 NSError
+ (NSError *)errorFromADMError:(nullable ADMError *)admError
                   defaultCode:(ADMTopOnErrorCode)defaultCode
            defaultDescription:(NSString *)defaultDescription;

/// 主线程安全派发
+ (void)dispatchOnMainThread:(dispatch_block_t)block;

@end

NS_ASSUME_NONNULL_END
