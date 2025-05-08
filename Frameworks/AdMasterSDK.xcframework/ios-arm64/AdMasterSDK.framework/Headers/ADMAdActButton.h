//
//  ADMAdActButton.h
//  AdMasterSDK
//
//  Created by sunmingzhe01 on 2021/2/23.
//  Copyright © 2021 AdMaster Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ADMNativeAdObject;

@interface ADMAdActButton : UIButton

/**
 * 设置用户点击行为的文案
 */
- (void)setData:(ADMNativeAdObject *)object;

@end
