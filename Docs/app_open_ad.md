# App Open Ads (App Open / Splash)

App Open ads use `ADMSplashAd` and are designed for startup scenarios such as cold starts and warm starts. The recommended flow is to call `load` first, then present the ad after the success callback is received and `isReady` is confirmed.

## Integration Flow

```
load -> splashAdDidReceiveAd/isReady -> present -> impression/click/close callbacks -> recreate or reload
```

## Objective-C

```objc
ADMSplashAd *splash = [[ADMSplashAd alloc] init];
splash.delegate = self;
splash.fullScreenContentDelegate = self;
splash.adUnitTag = @"your_splash_ad_unit_tag";
splash.adSize = [UIScreen mainScreen].bounds.size;
splash.request = [ADMRequest defaultRequest]; // Default timeout: 3 seconds
[splash load];
```

```objc
- (void)splashAdDidReceiveAd:(ADMSplashAd *)splashAd {
    if ([splashAd isReady]) {
        [splashAd presentInContainerView:self.view
                presentingViewController:self];
    }
}

- (void)splashAd:(ADMSplashAd *)splashAd didFailToReceiveAdWithError:(NSError *)error {
    // Loading failed. Continue to the app's main flow.
}
```

You can also load and present in one step:

```objc
[splash loadAndPresentInContainerView:containerView
             presentingViewController:self];
```

Class method loading (optional):

```objc
[ADMSplashAd loadWithAdUnitTag:@"your_splash_ad_unit_tag"
                       request:[ADMRequest defaultRequest]
             completionHandler:^(ADMSplashAd *ad, NSError *error) {
    if (ad && [ad isReady]) {
        ad.fullScreenContentDelegate = self;
        [ad presentInContainerView:self.view presentingViewController:self];
    }
}];
```

## Swift

```swift
import AdMasterSDK

let splash = ADMSplashAd()
splash.delegate = self
splash.fullScreenContentDelegate = self
splash.adUnitTag = "your_splash_ad_unit_tag"
splash.adSize = UIScreen.main.bounds.size
splash.load()
```

```swift
extension ViewController: ADMSplashDelegate {
    func splashAdDidReceive(_ splashAd: ADMSplashAd) {
        guard splashAd.isReady() else { return }
        splashAd.present(inContainerView: view, presenting: self)
    }

    func splashAd(_ splashAd: ADMSplashAd, didFailToReceiveAdWithError error: Error) {
        // Loading failed. Continue to the app's main flow.
    }
}
```

Class method loading (optional):

```swift
ADMSplashAd.load(withAdUnitTag: "your_splash_ad_unit_tag", request: ADMRequest.default()) { ad, error in
    guard let ad, ad.isReady() else { return }
    ad.fullScreenContentDelegate = self
    ad.present(inContainerView: view, presenting: self)
}
```

## Callbacks

### `ADMSplashDelegate`

| Method | Description |
| --- | --- |
| `splashAdDidReceiveAd:` | Loading succeeded. The ad can be presented. |
| `splashAd:didFailToReceiveAdWithError:` | Loading failed. |
| `splashAdDidSkip:` | The user skipped the ad. |

### `ADMFullScreenContentDelegate`

| Method | Description |
| --- | --- |
| `adWillPresentFullScreenContent:` | The ad is about to be presented. |
| `adDidRecordImpression:` | Impression recorded. |
| `adDidRecordClick:` | Click recorded. |
| `ad:didFailToPresentFullScreenContentWithError:` | Presentation failed. |
| `adWillDismissFullScreenContent:` | The ad is about to be dismissed. |
| `adDidDismissFullScreenContent:` | The ad has been dismissed. |

## S2S Bidding

`ADMSplashAd` supports `getBiddingToken`, `loadBiddingAdWithTokenId:`, `loadBiddingAdWithADMData:`, and bid win/loss notifications. See [s2s_bidding.md](s2s_bidding.md) for the full flow.

## Notes

- Keep a strong reference to the `ADMSplashAd` instance until loading and presentation finish.
- For cold starts, use a fallback timeout and continue to the app's main flow promptly when loading or presentation fails.
- Each load is valid for one presentation only. After dismissal, recreate the instance or load a new ad.
- Check `isReady` before presenting the ad.
- Handle presentation and UI transitions on the main thread.
- See [error_codes.md](error_codes.md) for error codes.
