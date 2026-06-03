//
//  ADMPermissionSettings.h
//  AdMasterSDK
//
//  Created by yangdingjia on 2021/6/29.
//  Copyright © 2021 AdMaster Inc. All rights reserved.
//

#ifndef ADMPermissionSettings_h
#define ADMPermissionSettings_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ADMPermissionSettings : NSObject

+ (instancetype)sharedInstance;

/**
 * Allow the SDK to read and send IDFA in ad requests.
 * When NO, ``idfa`` is sent as an empty string.
 * When YES, IDFA is read only if ATT allows tracking (iOS 14+) or LAT is enabled (earlier OS); the value is sent as-is, including all-zero UUID.
 * The host app must present the ATT prompt; the SDK does not call ``requestTrackingAuthorization``.
 * @param permissionGranted YES to allow (default YES).
 */
- (void)setReadDeviceIdPermission:(BOOL)permissionGranted;

/**
 * Allow reading device storage info.
 * @param permissionGranted YES to allow (default YES).
 */
- (void)setReadStorageInfoPermission:(BOOL)permissionGranted;

@end

NS_ASSUME_NONNULL_END

#endif /* ADMPermissionSettings_h */
