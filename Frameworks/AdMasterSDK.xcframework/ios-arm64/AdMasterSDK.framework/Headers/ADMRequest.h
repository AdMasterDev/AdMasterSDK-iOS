//
//  ADMRequest.h
//  AdMasterSDK
//

#ifndef ADMRequest_h
#define ADMRequest_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ADMRequest : NSObject <NSCopying>

@property (nonatomic, copy, nullable) NSString *channelId;
@property (nonatomic, assign) BOOL enableLocation;
@property (nonatomic, assign) int bidFloor;
@property (nonatomic, assign) NSTimeInterval timeout;

+ (instancetype)defaultRequest;

@end

NS_ASSUME_NONNULL_END

#endif /* ADMRequest_h */
