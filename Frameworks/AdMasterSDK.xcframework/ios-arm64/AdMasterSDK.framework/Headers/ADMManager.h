//
//  ADMManager.h
//  AdMasterSDK
//
//  Created by yangdingjia on 2024/6/24.
//

#ifndef ADMManager_h
#define ADMManager_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ADMManager : NSObject

/// Initializes the SDK (pre-initialization work may run here).
+ (void)startWithAppsid:(NSString *)appsid completionHandler:(void (^)(BOOL, NSError * _Nullable))completionHandler;

+ (NSString *)getSDKVersion;

@end

NS_ASSUME_NONNULL_END

#endif /* ADMManager_h */
