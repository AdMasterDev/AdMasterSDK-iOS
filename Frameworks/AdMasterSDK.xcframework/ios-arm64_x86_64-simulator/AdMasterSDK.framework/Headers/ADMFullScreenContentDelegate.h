//
//  ADMFullScreenContentDelegate.h
//  AdMasterSDK
//

#ifndef ADMFullScreenContentDelegate_h
#define ADMFullScreenContentDelegate_h

#import <Foundation/Foundation.h>
#import <AdMasterSDK/ADMError.h>

NS_ASSUME_NONNULL_BEGIN

/// Presentation lifecycle for full-screen ad formats. All methods are called on the main thread.
@protocol ADMFullScreenContentDelegate <NSObject>

@optional

- (void)adWillPresentFullScreenContent:(id)ad;
- (void)adWillDismissFullScreenContent:(id)ad;
- (void)adDidDismissFullScreenContent:(id)ad;
- (void)ad:(id)ad didFailToPresentFullScreenContentWithError:(NSError *)error;
- (void)adDidRecordImpression:(id)ad;
- (void)adDidRecordClick:(id)ad;

@end

NS_ASSUME_NONNULL_END

#endif /* ADMFullScreenContentDelegate_h */
