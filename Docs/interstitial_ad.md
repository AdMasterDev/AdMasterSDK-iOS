# Interstitial Ads

Interstitial ads use `ADMInterstitialAd` and are suitable for natural pause points, such as after a level ends or during page transitions.

## Integration Flow

```
load -> interstitialAdDidReceiveAd/isReady -> present -> impression/click/close callbacks -> recreate or reload
```

## Objective-C

```objc
ADMInterstitialAd *interstitial = [[ADMInterstitialAd alloc] init];
interstitial.adUnitTag = @"your_interstitial_ad_unit_tag";
interstitial.delegate = self;
interstitial.fullScreenContentDelegate = self;
interstitial.request = [ADMRequest defaultRequest];
[interstitial load];
```

```objc
- (void)interstitialAdDidReceiveAd:(ADMInterstitialAd *)ad {
    if ([ad isReady]) {
        [ad presentFromViewController:self];
    }
}

- (void)interstitialAd:(ADMInterstitialAd *)ad didFailToReceiveAdWithError:(NSError *)error {
    // Loading failed
}
```

Class method loading:

```objc
[ADMInterstitialAd loadWithAdUnitTag:@"your_interstitial_ad_unit_tag"
                             request:[ADMRequest defaultRequest]
                   completionHandler:^(ADMInterstitialAd *ad, NSError *error) {
    if (ad && [ad isReady]) {
        ad.fullScreenContentDelegate = self;
        [ad presentFromViewController:self];
    }
}];
```

## Swift

```swift
import AdMasterSDK

let interstitial = ADMInterstitialAd()
interstitial.adUnitTag = "your_interstitial_ad_unit_tag"
interstitial.delegate = self
interstitial.fullScreenContentDelegate = self
interstitial.load()
```

```swift
extension ViewController: InterstitialDelegate {
    func interstitialAdDidReceive(_ ad: ADMInterstitialAd) {
        guard ad.isReady() else { return }
        ad.present(from: self)
    }

    func interstitialAd(_ ad: ADMInterstitialAd, didFailToReceiveAdWithError error: Error) {
        // Loading failed
    }
}
```

Class method loading (optional):

```swift
ADMInterstitialAd.load(withAdUnitTag: "your_interstitial_ad_unit_tag", request: ADMRequest.default()) { ad, error in
    guard let ad, ad.isReady() else { return }
    ad.fullScreenContentDelegate = self
    ad.present(from: self)
}
```

## Callbacks

### `ADMInterstitialDelegate` / Swift `InterstitialDelegate`

| Method | Description |
| --- | --- |
| `interstitialAdDidReceiveAd:` | Loading succeeded. |
| `interstitialAd:didFailToReceiveAdWithError:` | Loading failed. |
| `interstitialAd:didRecordDislikeFeedback:` | The user submitted negative feedback. |

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

`ADMInterstitialAd` supports `getBiddingToken`, `loadBiddingAdWithTokenId:`, `loadBiddingAdWithADMData:`, `getECPMLevel`, `getPECPM`, `getAdDataForKey:`, and bid win/loss notifications. See [s2s_bidding.md](s2s_bidding.md) for the full flow.

## Notes

- Keep a strong reference to the `ADMInterstitialAd` instance until loading and presentation finish.
- Preload interstitial ads and present them at natural pause points.
- Calling `present` before `isReady` triggers the presentation failure callback and does not automatically start a new request.
- Each load is valid for one presentation only. After dismissal, recreate the instance or load a new ad.
- Handle presentation and UI transitions on the main thread.
- See [error_codes.md](error_codes.md) for error codes.
