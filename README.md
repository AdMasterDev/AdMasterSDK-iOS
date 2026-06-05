# Set Up the AdMaster Mobile Ads SDK

This guide explains how to integrate **AdMasterSDK** into an iOS app and initialize the SDK. For ad loading, presentation, and callbacks by ad format, see the dedicated documents in the `Docs` directory.

## Prerequisites

- You are developing an iOS app with Xcode.
- The Deployment Target is iOS 12.0 or later.
- You have obtained an App ID (`appsid`, a hexadecimal string) and ad placement IDs (`adUnitTag`).

## Terminology

| Term | Description |
| --- | --- |
| `appsid` | App-level ID used to initialize the SDK. |
| `adUnitTag` | Ad placement ID. Each ad placement has its own value. |
| S2S Bidding | Server-to-server bidding. The SDK generates a token. After the publisher server completes bidding, the app notifies the SDK to load the winning ad. |

## Import the SDK

Choose one of the following integration methods. CocoaPods is recommended.

### CocoaPods

Add the following dependency to the app target's `Podfile`:

```ruby
pod 'AdMasterSDK'
```

Run:

```bash
pod install --repo-update
```

Then open the project with the generated `.xcworkspace`.

### Manual Integration

1. Download the release package: [AdMasterSDK-iOS](https://github.com/AdMasterDev/AdMasterSDK-iOS).
2. Drag `Frameworks/AdMasterSDK.xcframework` into your project.
3. Drag `Resources/AdMasterSDKRes.bundle` into your project.
4. Add `-ObjC` to Other Linker Flags in Build Settings.
5. Link the required system frameworks: `AdSupport`, `AppTrackingTransparency`, `AVFoundation`, `CoreGraphics`, `CoreLocation`, `CoreMotion`, `CoreTelephony`, `QuartzCore`, `SystemConfiguration`, `SafariServices`, `StoreKit`, and `WebKit`.

## Initialize the SDK

Before loading any ad, initialize the SDK with `ADMManager`. This method only needs to be called once. It is recommended to call it early during app startup.

### Objective-C

```objc
#import <AdMasterSDK/AdMasterSDK.h>

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [ADMManager startWithAppsid:@"your_app_id"
              completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            NSLog(@"AdMasterSDK initialized");
        } else {
            NSLog(@"AdMasterSDK init failed: %@", error);
        }
    }];
    return YES;
}
```

### Swift

```swift
import AdMasterSDK

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    ADMManager.start(withAppsid: "your_app_id") { success, error in
        if success {
            NSLog("AdMasterSDK initialized")
        } else {
            NSLog("AdMasterSDK init failed: %@", String(describing: error))
        }
    }
    return true
}
```

## Integration Notes

- Keep a strong reference to each ad object while it is loading or being displayed. This applies to full-screen ad objects such as `ADMSplashAd`, `ADMInterstitialAd`, and `ADMRewardedAd`, as well as `ADMNativeAdLoader`, `ADMNativeAdObject`, and `ADMBannerView`.
- Delegates are held weakly by the SDK. Keep the delegate owner alive for the full loading and presentation lifecycle.
- Ad callbacks are delivered on the main thread. Perform UI updates, presentation, view registration, and reward UI changes on the main thread. Move long-running business logic, logging, or server requests to a background queue when needed.

## Global Configuration (Optional)

| API | Description |
| --- | --- |
| `ADMSetting.sharedInstance().isTest` / `[ADMSetting sharedInstance].isTest` | Marks requests as test traffic. Do not enable this in Release builds. |
| `ADMSetting.sharedInstance().isMock` / `[ADMSetting sharedInstance].isMock` | Uses fixed test ads and bypasses real bidding. Do not enable this in Release builds. |
| `setDebugLogEnable:` | Enables debug logs. Disabled by default. |
| `setLimitPersonalAds:` / `getLimitPersonalAds` | Limits personalized ads. |
| `setMaxVideoCacheCapacityMb:` | Sets the video cache capacity. Valid range: 15-100 MB. Default: 70 MB. |

## Documentation Index

| Document | Description |
| --- | --- |
| [error_codes.md](Docs/error_codes.md) | Error codes and `userInfo` keys. |
| [s2s_bidding.md](Docs/s2s_bidding.md) | Server-to-server bidding for Banner, App Open, Interstitial, Rewarded, and Native ads. |
| [app_open_ad.md](Docs/app_open_ad.md) | App Open ads (`ADMSplashAd`). |
| [banner_ad.md](Docs/banner_ad.md) | Banner ads (`ADMBannerView` / Swift `BannerView`). |
| [interstitial_ad.md](Docs/interstitial_ad.md) | Interstitial ads (`ADMInterstitialAd`). |
| [native_ad.md](Docs/native_ad.md) | Native ads (`ADMNativeAdLoader`). |
| [rewarded_ad.md](Docs/rewarded_ad.md) | Rewarded video ads (`ADMRewardedAd`). |
