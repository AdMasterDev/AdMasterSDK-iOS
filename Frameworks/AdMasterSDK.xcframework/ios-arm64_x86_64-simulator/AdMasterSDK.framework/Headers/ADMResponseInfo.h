//
//  ADMResponseInfo.h
//  AdMasterSDK
//

#ifndef ADMResponseInfo_h
#define ADMResponseInfo_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Metadata for a successfully loaded ad (placement, response id, bid layer, encrypted price).
@interface ADMResponseInfo : NSObject

@property (nonatomic, copy, readonly) NSString *adUnitTag;
@property (nonatomic, copy, readonly, nullable) NSString *responseIdentifier;
/// Winning bid layer in cents (string), when available.
@property (nonatomic, copy, readonly, nullable) NSString *ecpmLevel;
/// Encrypted price string from the server, when available.
@property (nonatomic, copy, readonly, nullable) NSString *encryptedEcpm;

+ (instancetype)infoWithAdUnitTag:(NSString *)adUnitTag
               responseIdentifier:(nullable NSString *)responseIdentifier
                        ecpmLevel:(nullable NSString *)ecpmLevel
                    encryptedEcpm:(nullable NSString *)encryptedEcpm;

@end

NS_ASSUME_NONNULL_END

#endif /* ADMResponseInfo_h */
