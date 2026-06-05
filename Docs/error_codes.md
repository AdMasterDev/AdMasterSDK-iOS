# Error Codes

AdMasterSDK passes errors to delegates and completion callbacks through `NSError`. Integrators should log the `domain`, `code`, `localizedDescription`, and key `userInfo` fields to support troubleshooting.

## Domain

| Constant | Value |
| --- | --- |
| `ADMPublicErrorDomain` | `cc.admaster.sdk.public.ErrorDomain` |
| `ADMErrorDomain` | Same as `ADMPublicErrorDomain`. |

Objective-C:

```objc
if ([error.domain isEqualToString:ADMPublicErrorDomain]) {
    ADMErrorCode code = (ADMErrorCode)error.code;
}
```

Swift:

```swift
if (error as NSError).domain == ADMPublicErrorDomain {
    let code = (error as NSError).code
}
```

## `ADMErrorCode`

| Code | Enum | Meaning | Common Scenario |
| --- | --- | --- | --- |
| 1001 | `ADMErrorCodeNoFill` | No fill | The server did not return an available ad. |
| 1002 | `ADMErrorCodeNetworkError` | Network error | Timeout, connection failure, or server-side exception. |
| 1003 | `ADMErrorCodeInvalidConfig` | Invalid configuration | Invalid or unconfigured App ID or `adUnitTag`. |
| 2001 | `ADMErrorCodeDownloadFailed` | Creative download failed | Image, video, or other asset download failed. |
| 2002 | `ADMErrorCodeCacheFailed` | Cache failed | Local cache write or read failed. |
| 3001 | `ADMErrorCodeInvalidContent` | Invalid content | Creative URL, size, or other content does not meet requirements. |
| 3002 | `ADMErrorCodeShowFailed` | Presentation failed | Presenting before ready, or invalid container/ViewController. |
| 4001 | `ADMErrorCodePlaybackFailed` | Playback failed | Video playback error. |

## `userInfo` Extension Keys

| Key | Description |
| --- | --- |
| `ADMServerErrorCodeKey` | Original server error code string. |
| `ADMClientErrorCodeKey` | SDK client-side diagnostic code. |
| `ADMVisibilityFailCodeKey` | Native ad visibility verification failure code. |
| `ADMPlaybackErrorCodeKey` | Original player or media-layer error code. |

Objective-C:

```objc
NSString *serverCode = error.userInfo[ADMServerErrorCodeKey];
NSString *clientCode = error.userInfo[ADMClientErrorCodeKey];
```

Swift:

```swift
let nsError = error as NSError
let serverCode = nsError.userInfo[ADMServerErrorCodeKey] as? String
let clientCode = nsError.userInfo[ADMClientErrorCodeKey] as? String
```

## Common Callback Locations

| Format | Load Failure | Presentation / Impression Failure |
| --- | --- | --- |
| App Open `ADMSplashAd` | `splashAd:didFailToReceiveAdWithError:` | `ad:didFailToPresentFullScreenContentWithError:` |
| Interstitial `ADMInterstitialAd` | `interstitialAd:didFailToReceiveAdWithError:` | `ad:didFailToPresentFullScreenContentWithError:` |
| Rewarded `ADMRewardedAd` | `rewardedAd:didFailToReceiveAdWithError:` | `ad:didFailToPresentFullScreenContentWithError:` |
| Banner `ADMBannerView` | `bannerView:didFailToReceiveAdWithError:` | `bannerView:didFailToDisplayAdWithError:` |
| Native `ADMNativeAdLoader` | `nativeAdLoader:didFailToReceiveAdWithError:nativeAdObject:` | `nativeAd:didFailToRecordImpressionForView:error:` |

## Handling Recommendations

- `1001` No fill is a normal bidding result. Retry later or switch to another ad placement if needed.
- For `1003` invalid configuration, check `appsid` and `adUnitTag`.
- For `3002` presentation failure, confirm that a load success callback has been received, `isReady == YES`, and the container and ViewController are valid.
- For `4001` playback failure, log `ADMPlaybackErrorCodeKey`.
- When troubleshooting, log the error code, ad format, ad placement ID, and callback method name together.
