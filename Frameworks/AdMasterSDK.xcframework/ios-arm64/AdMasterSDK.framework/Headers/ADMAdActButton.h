//
//  ADMAdActButton.h
//  AdMasterSDK
//
//  Created by sunmingzhe01 on 2021/2/23.
//  Copyright © 2021 AdMaster Inc. All rights reserved.
//

#ifndef ADMAdActButton_h
#define ADMAdActButton_h

#import <UIKit/UIKit.h>
@class ADMNativeAdObject;

@interface ADMAdActButton : UIButton

/**
 * Sets CTA label text from the ad object.
 */
- (void)setData:(ADMNativeAdObject *)object;

@end

#endif /* ADMAdActButton_h */
