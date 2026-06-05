# Rewarded Video Ads

Rewarded video ads use `ADMRewardedAd`. After the user meets the viewing requirement, the SDK notifies the app through the reward callback so the app can grant coins, items, or other rewards.

## Integration Flow

```
load -> rewardedAdDidReceiveAd/isReady -> present -> playback complete/reward/skip -> close -> recreate or reload
```

## Objective-C

```objc
ADMRewardedAd *rewarded = [[ADMRewardedAd alloc] init];
rewarded.adUnitTag = @"your_rewarded_ad_unit_tag";
rewarded.delegate = self;
rewarded.fullScreenContentDelegate = self;
rewarded.userID = @"user_id";       // Optional
rewarded.extraInfo = @"extra_info"; // Optional
rewarded.request = [ADMRequest defaultRequest];
[rewarded load];
```

```objc
- (void)rewardedAdDidReceiveAd:(ADMRewardedAd *)ad {
    if ([ad isReady]) {
        [ad presentFromViewController:self];
    }
}

- (void)rewardedAd:(ADMRewardedAd *)ad userDidEarnReward:(ADMReward *)reward {
    // Grant the reward here
}

- (void)rewardedAd:(ADMRewardedAd *)ad didFailToReceiveAdWithError:(NSError *)error {
    // Loading failed
}
```

Class method loading (optional):

```objc
[ADMRewardedAd loadWithAdUnitTag:@"your_rewarded_ad_unit_tag"
                         request:[ADMRequest defaultRequest]
               completionHandler:^(ADMRewardedAd *ad, NSError *error) {
    if (ad && [ad isReady]) {
        ad.fullScreenContentDelegate = self;
        [ad presentFromViewController:self];
    }
}];
```

## Swift

```swift
import AdMasterSDK

let rewarded = ADMRewardedAd()
rewarded.adUnitTag = "your_rewarded_ad_unit_tag"
rewarded.delegate = self
rewarded.fullScreenContentDelegate = self
rewarded.userID = "user_id"       // Optional
rewarded.extraInfo = "extra_info" // Optional
rewarded.load()
```

```swift
extension ViewController: RewardedDelegate {
    func rewardedAdDidReceive(_ ad: ADMRewardedAd) {
        guard ad.isReady() else { return }
        ad.present(from: self)
    }

    func rewardedAd(_ ad: ADMRewardedAd, userDidEarn reward: ADMReward) {
        // Grant the reward here
    }

    func rewardedAd(_ ad: ADMRewardedAd, didFailToReceiveAdWithError error: Error) {
        // Loading failed
    }
}
```

Class method loading (optional):

```swift
ADMRewardedAd.load(withAdUnitTag: "your_rewarded_ad_unit_tag", request: ADMRequest.default()) { ad, error in
    guard let ad, ad.isReady() else { return }
    ad.fullScreenContentDelegate = self
    ad.present(from: self)
}
```

## Callbacks

### `ADMRewardedDelegate` / Swift `RewardedDelegate`

| Method | Description |
| --- | --- |
| `rewardedAdDidReceiveAd:` | Loading succeeded. |
| `rewardedAd:didFailToReceiveAdWithError:` | Loading failed. |
| `rewardedAd:userDidEarnReward:` | Reward grant timing. |
| `rewardedAdDidCompleteVideo:` | Video playback completed. |
| `rewardedAd:didSkipWithProgress:` | The user skipped the video. `progress` is in the range 0.0-1.0. |

### `ADMFullScreenContentDelegate`

| Method | Description |
| --- | --- |
| `adWillPresentFullScreenContent:` | The ad is about to be presented. |
| `adDidRecordImpression:` | Impression recorded. |
| `adDidRecordClick:` | Click recorded. |
| `ad:didFailToPresentFullScreenContentWithError:` | Presentation or playback failed. |
| `adWillDismissFullScreenContent:` | The ad is about to be dismissed. |
| `adDidDismissFullScreenContent:` | The ad has been dismissed. |

## S2S Bidding

`ADMRewardedAd` supports `getBiddingToken`, `loadBiddingAdWithTokenId:`, `loadBiddingAdWithADMData:`, `getECPMLevel`, `getPECPM`, `getAdDataForKey:`, and bid win/loss notifications. See [s2s_bidding.md](s2s_bidding.md) for the full flow.

## Notes

- Keep a strong reference to the `ADMRewardedAd` instance until loading and presentation finish.
- Grant rewards only in `rewardedAd:userDidEarnReward:` / Swift `rewardedAd(_:userDidEarn:)`. Do not rely only on the close callback.
- Do not call `load` repeatedly during playback.
- Each load is valid for one presentation only. After dismissal, recreate the instance or load a new ad.
- Handle presentation, reward UI updates, and close transitions on the main thread.
- See [error_codes.md](error_codes.md) for error codes.
