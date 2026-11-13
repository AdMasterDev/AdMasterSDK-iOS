//
//  ALAdMasterMediationAdapter.h
//  Mediation/MAX
//
//  Entry point for the AppLovin MAX custom SDK mediation adapter. In the MAX dashboard, add a
//  Custom Network (SDK) and set iOS Adapter Class Name to ALAdMasterMediationAdapter.
//

#import <Foundation/Foundation.h>
#if __has_include(<AppLovinSDK/AppLovinSDK.h>)
#import <AppLovinSDK/AppLovinSDK.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface ALAdMasterMediationAdapter : ALMediationAdapter <MAAppOpenAdapter,
                                                            MAInterstitialAdapter,
                                                            MARewardedAdapter,
                                                            MAAdViewAdapter,
                                                            MANativeAdAdapter,
                                                            MASignalProvider>

@end

NS_ASSUME_NONNULL_END
