//
//  ADMReward.h
//  AdMasterSDK
//

#ifndef ADMReward_h
#define ADMReward_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ADMReward : NSObject

@property (nonatomic, copy) NSString *type;
@property (nonatomic, assign) NSInteger amount;

+ (instancetype)rewardWithType:(NSString *)type amount:(NSInteger)amount;

@end

NS_ASSUME_NONNULL_END

#endif /* ADMReward_h */
