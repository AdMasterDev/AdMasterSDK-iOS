//
//  ADMManager.h
//  AdMasterSDK
//
//  Created by yangdingjia on 2024/6/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ADMManager : NSObject

/// 初始化函数，SDK可在此函数做些预初始化
+ (void)startWithAppsid:(NSString *)appsid completionHandler:(void (^)(BOOL, NSError * _Nullable))completionHandler;

+ (NSString *)getSDKVersion;

@end

NS_ASSUME_NONNULL_END
