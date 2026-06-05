# Native Ads

Native ads are loaded with `ADMNativeAdLoader`, which returns `ADMNativeAdObject` instances. Apps can render their own UI or use `ADMNativeAdView` to assist with rendering.

## Integration Flow

```
Create ADMNativeAdLoader -> load -> didReceiveNativeAds -> select a non-expired ad -> render UI -> register interaction and callbacks
```

## Objective-C

```objc
ADMNativeAdLoader *loader = [[ADMNativeAdLoader alloc] init];
loader.delegate = self;
loader.adUnitTag = @"your_native_ad_unit_tag";
loader.presentAdViewController = self;
loader.request = [ADMRequest defaultRequest];
loader.cachesVideoAssets = YES;
[loader load];
```

```objc
- (void)nativeAdLoader:(ADMNativeAdLoader *)loader didReceiveNativeAds:(NSArray<ADMNativeAdObject *> *)ads {
    ADMNativeAdObject *object = nil;
    for (ADMNativeAdObject *candidate in ads) {
        if (![candidate isExpired]) {
            object = candidate;
            break;
        }
    }
    if (!object) { return; }

    object.interactionDelegate = self;
    [self displayNativeAdObject:object];
}

- (void)nativeAdLoader:(ADMNativeAdLoader *)loader didFailToReceiveAdWithError:(NSError *)error
        nativeAdObject:(ADMNativeAdObject *)adObject {
    // Loading failed
}
```

Render with `ADMNativeAdView`:

```objc
[adView loadAndDisplayNativeAdWithObject:object
                              completion:^(NSArray *errors) {
    if (errors.count == 0) {
        // Rendering completed
    }
}];
```

Register impressions and clicks for custom rendering:

```objc
[object registerViewForInteraction:containerView
                         mediaView:mediaView
                    clickableViews:@[titleLabel, imageView, actButton]
                    viewController:self];
```

Unregister before the page is destroyed or before a cell is reused:

```objc
[object unregisterView:containerView];
```

## Swift

```swift
import AdMasterSDK

let loader = ADMNativeAdLoader()
loader.delegate = self
loader.adUnitTag = "your_native_ad_unit_tag"
loader.presentAdViewController = self
loader.load()
```

```swift
extension ViewController: ADMNativeAdLoaderDelegate, ADMNativeInteractionDelegate {
    func nativeAdLoader(_ loader: ADMNativeAdLoader, didReceiveNativeAds ads: [ADMNativeAdObject]) {
        guard let object = ads.first(where: { !$0.isExpired() }) else { return }
        object.interactionDelegate = self
        display(object: object)
    }

    func nativeAdLoader(_ loader: ADMNativeAdLoader,
                        didFailToReceiveAdWithError error: Error,
                        nativeAdObject adObject: ADMNativeAdObject?) {
        // Loading failed
    }
}
```

Render with `ADMNativeAdView`:

```swift
adView.loadAndDisplayNativeAd(with: object) { errors in
    if errors?.isEmpty ?? true {
        // Rendering completed
    }
}
```

Register impressions and clicks for custom rendering:

```swift
object.registerView(forInteraction: containerView,
                    mediaView: mediaView,
                    clickableViews: [titleLabel, imageView, actButton],
                    viewController: self)
```

Unregister before the page is destroyed or before a cell is reused:

```swift
object.unregisterView(containerView)
```

## Common `ADMNativeAdObject` Fields

| Property / Method | Description |
| --- | --- |
| `title` / `text` / `brandName` | Title, description, and brand text. |
| `iconImageURLString` / `mainImageURLString` / `morepics` | Icon, main image, and multi-image URLs. |
| `videoURLString` / `videoDuration` / `autoPlay` | Video URL, duration, and autoplay flag. |
| `materialType` | Creative type: `NORMAL`, `VIDEO`, `HTML`, or `GIF`. |
| `actType` | Click action: `ADMNativeAdActionTypeLP`, `ADMNativeAdActionTypeDL`, or `ADMNativeAdActionTypeDeepLink`. |
| `actButtonString` | CTA text. |
| `w` / `h` / `aspectRatio` | Main image size and aspect ratio. |
| `isExpired` / Swift `isExpired()` | Whether the ad has expired. Request a new ad after expiration. |
| `getECPMLevel` / `getPECPM` | Price tier and encrypted price. Read these only after the ad object has loaded successfully. |

## Callbacks

| Method | Description |
| --- | --- |
| `nativeAdLoader:didReceiveNativeAds:` | Loading succeeded and returns an array of `ADMNativeAdObject`. |
| `nativeAdLoader:didFailToReceiveAdWithError:nativeAdObject:` | Loading failed. Some bidding failure scenarios may include an `adObject` for reporting. |
| `nativeAd:didRecordImpressionForView:` | Impression recorded. |
| `nativeAd:didFailToRecordImpressionForView:error:` | Impression recording failed. Read `ADMVisibilityFailCodeKey` if needed. |
| `nativeAd:didRecordClickForView:` | Click recorded. |
| `nativeAd:didDismissLandingPageFromView:` | Landing page dismissed. |
| `nativeAd:didDismissDislikeWithReasonCode:` | Negative feedback reason code. |

## S2S Bidding

`ADMNativeAdLoader` supports `getBiddingToken`, `loadBiddingAdWithTokenId:`, and `loadBiddingAdWithADMData:`. Bid win/loss notifications, `getECPMLevel`, `getPECPM`, and `getAdDataForKey:` are called on the `ADMNativeAdObject` returned after successful loading. See [s2s_bidding.md](s2s_bidding.md) for the full flow.

## Notes

- Keep strong references to the `ADMNativeAdLoader` and the selected `ADMNativeAdObject` until loading, rendering, and interaction registration are no longer needed.
- In list scenarios, call `unregisterView` before reusing a cell.
- Before rendering, filter for ad objects where `isExpired == NO`.
- Use `ADMNativeVideoView` for video creatives and implement `ADMNativeVideoViewDelegate`.
- Images can be loaded through the SDK cache with `loadImageWithURLString:completion:` / Swift `loadImage(withURLString:)`.
- Register and unregister views on the main thread.
- See [error_codes.md](error_codes.md) for error codes.
