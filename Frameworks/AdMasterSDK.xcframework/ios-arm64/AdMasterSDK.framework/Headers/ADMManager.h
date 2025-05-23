//
//  ADMManager.h
//  AdMasterSDK
//
//  Created by yangdingjia on 2024/6/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ADMManager : NSObject

/// 初始化SDK
/// - Parameter completionHandler: 初始化回调
+ (void)startWithCompletionHandler:(void(^)(BOOL success, NSError * _Nullable error))completionHandler;

+ (void)setAppsid:(NSString *)appsid;

+ (NSString *)getSDKVersion;

@end

NS_ASSUME_NONNULL_END
