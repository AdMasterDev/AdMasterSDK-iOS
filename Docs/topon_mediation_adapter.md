# TopOn (AnyThink) Mediation Adapter

`TopOnMediationAdMaster` is the TopOn (AnyThink) custom ad network adapter for AdMaster SDK. It supports both standard Waterfall loading and C2S Header Bidding (including win/loss reporting).

## CocoaPods

Add the following dependency to your app target's `Podfile`:

```ruby
pod 'TopOnMediationAdMaster'
```

Run:

```bash
pod install --repo-update
```

This Pod automatically depends on `AnyThinkiOS` and `AdMasterSDK`. You do not need to add the main SDK Pod separately.

## TopOn Dashboard Configuration

In the TopOn Developer Dashboard, go to **Network** -> **Add Custom Network**, and configure the iOS Adapter Class Name for each ad format:

| Ad Format | iOS Adapter Class Name |
| --- | --- |
| Rewarded Video | `ADMTopOnRewardedAdapter` |
| Interstitial | `ADMTopOnInterstitialAdapter` |
| Banner | `ADMTopOnBannerAdapter` |
| Splash | `ADMTopOnSplashAdapter` |
| Native (Self-Render) | `ADMTopOnNativeAdapter` |

### Parameter Configuration

When adding an Ad Source, custom parameters can be configured as top-level keys or inside `custom_ext` JSON:

```json
{
  "app_id": "your_app_id",
  "placement_id": "your_placement_id",
  "bid_floor": 100,
  "test": false,
  "mock": false
}
```

| Field | Required | Description |
| --- | --- | --- |
| `app_id` | Yes | AdMaster App ID used to initialize the SDK. |
| `placement_id` | Yes | AdMaster placement ID (also accepts `ad_unit_id` and `slot_id`). |
| `bid_floor` | No | Bidding floor price in cents (integer); passed to `ADMRequest.bidFloor` when `> 0`. |
| `test` | No | Marks requests as test traffic. Do not enable this in Release builds. |
| `mock` | No | Uses fixed mock ads. Do not enable this in Release builds. |
| `ad_width` / `ad_height` | No | Banner or Splash dimensions (also accepts `width` / `height`). Banner defaults to `320x50`. |
| `user_id` / `custom_data` | No | Rewarded video server-side verification user ID and custom payload. |

## C2S Header Bidding and Win/Loss Notifications

1. **Enable C2S Bidding**: Enable Header Bidding (client-side C2S bidding) when creating the ad source in the TopOn Dashboard.
2. **Bidding Flow**:
   - TopOn invokes the adapter's `startBiddingRequestWithInfo:localInfo:completion:`.
   - After preloading the ad, the adapter reads the eCPM in cents via `[ad getECPMLevel]` and returns an `ATBidInfo` along with `ADMTopOnBiddingNotice` to TopOn.
3. **Win/Loss Reporting**:
   - **Win**: `ADMTopOnBiddingNotice` automatically calls `biddingSuccessWithSecondInfo:completion:` on the AdMaster ad object to report second-price (`ecpm`).
   - **Loss**: `ADMTopOnBiddingNotice` maps TopOn's `ATBiddingLossType` to AdMaster standard loss reason codes (`103` low price in normal, `102` low price in HB, `2` bidding timeout, `5` ad expired) and calls `biddingFailWithWinInfo:completion:`.

## Native Self-Render Integration (`ADMTopOnNativeAd`)

When a native ad loads successfully, an `ADMTopOnNativeAd` wrapper instance is returned with `title`, `text`, `ctaText`, `advertiser`, `iconUrl`, `imageUrl`, `imageList`, and `mediaView`.

After laying out your custom native views, bind the container and clickable views to enable impression tracking and click handling:

```objc
[nativeAd registerClickableViews:@[titleLabel, ctaButton, mainImageView]
                     inContainer:adContainerView
                  viewController:self];
```

Before destroying or reusing the ad view, call `[nativeAd unregisterView]` to unbind views and release the media player.

## Notes

- `ADMTopOnSplashAdapter` automatically cleans up its internal container and calls `[splashAd stop]` when the splash ad closes, fails to present, or is destroyed, preventing transparent overlay views from blocking screen touches.
- See [error_codes.md](error_codes.md) for AdMaster error codes.
