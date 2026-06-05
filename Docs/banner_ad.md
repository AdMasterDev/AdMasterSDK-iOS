# Banner Ads

Banner ads use `ADMBannerView`, a `UIView` subclass. After adding the banner view to the view hierarchy and calling `loadAd`, the ad is displayed when loading succeeds. No `present` call is required.

## Integration Flow

```
Create ADMBannerView -> add it to the view hierarchy -> loadAd -> loading/impression/click callbacks
```

## Objective-C

```objc
CGSize adSize = CGSizeMake(320, 50);
ADMBannerView *banner = [[ADMBannerView alloc] initWithAdSize:adSize
                                                    adUnitTag:@"your_banner_ad_unit_tag"];
banner.delegate = self;
banner.request = [ADMRequest defaultRequest];
[self.view addSubview:banner];
[banner loadAd];
```

```objc
- (void)bannerViewDidReceiveAd:(ADMBannerView *)bannerView {
    // Loading succeeded
}

- (void)bannerView:(ADMBannerView *)bannerView didFailToReceiveAdWithError:(NSError *)error {
    // Loading failed
}

- (void)bannerViewDidRecordImpression:(ADMBannerView *)bannerView {
    // Impression recorded
}

- (void)bannerViewDidRecordClick:(ADMBannerView *)bannerView {
    // Click recorded
}
```

## Swift

```swift
import AdMasterSDK

let adSize = CGSize(width: 320, height: 50)
let banner = BannerView(adSize: adSize, adUnitTag: "your_banner_ad_unit_tag")
banner.delegate = self
view.addSubview(banner)
banner.loadAd()
```

```swift
extension ViewController: BannerDelegate {
    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        // Loading succeeded
    }

    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        // Loading failed
    }

    func bannerViewDidRecordImpression(_ bannerView: BannerView) {
        // Impression recorded
    }

    func bannerViewDidRecordClick(_ bannerView: BannerView) {
        // Click recorded
    }
}
```

## Callbacks

| Method | Description |
| --- | --- |
| `bannerViewDidReceiveAd:` | Loading succeeded. |
| `bannerView:didFailToReceiveAdWithError:` | Loading failed. |
| `bannerViewDidRecordImpression:` | Impression recorded. |
| `bannerView:didFailToDisplayAdWithError:` | Display failed. |
| `bannerViewDidRecordClick:` | Click recorded. |
| `bannerViewDidDismiss:` | Closed. Availability depends on whether the ad creative supports closing. |

## S2S Bidding

Banner ads support `getBiddingToken`, `loadBiddingAdWithTokenId:`, `loadBiddingAdWithADMData:`, `getECPMLevel`, `getPECPM`, `getAdDataForKey:`, and bid win/loss notifications. See [s2s_bidding.md](s2s_bidding.md) for the full flow.

## Notes

- Keep a strong reference to the `ADMBannerView` instance for as long as the banner should load, display, or refresh.
- `adSize` must match the size configured for the ad placement in the platform.
- When the page is destroyed or refreshed, remove the old `ADMBannerView` and create a new instance for loading.
- Standard Banner ads support SDK-managed automatic refresh. In S2S Bidding scenarios, the publisher must run bidding again and then call `loadBiddingAdWithTokenId:`. Do not reuse an old token or old `adid`.
- Handle view hierarchy updates on the main thread.
- See [error_codes.md](error_codes.md) for error codes.
