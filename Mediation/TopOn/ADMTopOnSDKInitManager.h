#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^ADMTopOnSDKInitCompletion)(BOOL success, NSError *_Nullable error);

/**
 * TopOn 适配器底层 AdMasterSDK 线程安全初始化管理器
 * 对标 Android: AdMasterTopOnInitManager + AdMasterTopOnSDKWrapper
 */
@interface ADMTopOnSDKInitManager : NSObject

+ (instancetype)sharedInstance;

/// 当前 SDK 是否已完成初始化
@property (nonatomic, assign, readonly) BOOL isInitialized;

/// 当前已初始化的 AppID
@property (nonatomic, copy, readonly, nullable) NSString *initializedAppID;

/// 获取底层 AdMasterSDK 版本号
+ (NSString *)sdkVersion;

/// 获取 TopOn Adapter 版本号
+ (NSString *)adapterVersion;

/// 线程安全初始化 SDK（支持并发等待队列，失败自动允许下次重试，completion 保证在主线程回调）
- (void)initSDKWithAppID:(nullable NSString *)appID
             serverExtra:(nullable NSDictionary *)serverExtra
              localExtra:(nullable NSDictionary *)localExtra
              completion:(ADMTopOnSDKInitCompletion)completion;

/// 仅供单元测试重置初始化状态使用
- (void)resetForTesting;

@end

NS_ASSUME_NONNULL_END
