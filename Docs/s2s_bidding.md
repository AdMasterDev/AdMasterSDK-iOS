# S2S Bidding (Server-to-Server Bidding)

S2S Bidding means the SDK generates an encrypted token, the app sends the token to the publisher server for bidding, and after the server returns the winning `adid`, the app notifies the SDK to load and display the winning ad.

Ad formats that support S2S Bidding:

| Format | Supported Class |
| --- | --- |
| Banner | `ADMBannerView` |
| App Open | `ADMSplashAd` |
| Interstitial | `ADMInterstitialAd` |
| Rewarded Video | `ADMRewardedAd` |
| Native | Loaded by `ADMNativeAdLoader`; bid win/loss notifications are reported through `ADMNativeAdObject` |

## Integration Flow

1. Complete [SDK initialization](../README.md).
2. Create the ad object and set `adUnitTag`.
3. Call `getBiddingToken` to obtain a token.
4. The app submits the token to the publisher server, and the server calls the AdMaster bidding API.
5. The server returns the winning ad's `adid`.
6. The app calls `loadBiddingAdWithTokenId:` / Swift `loadBiddingAd(withTokenId:)`.
7. After receiving the load success callback, present or render the ad according to its format.
8. Call bid win or bid loss reporting as needed.

Tokens are recommended for single bidding and single use only. Do not reuse a token across ad placements or requests.

## Objective-C

```objc
NSString *token = [ad getBiddingToken];
// Send the token to the publisher server. The server returns winnerAdId.
[ad loadBiddingAdWithTokenId:winnerAdId];
```

```objc
[ad biddingSuccessWithSecondInfo:@{@"ecpm": @(secondPrice), @"adn": @(channel)}
                      completion:^(BOOL success, NSString *errorInfo) {
    // Bid win reporting result
}];

[ad biddingFailWithWinInfo:@{@"ecpm": @(winPrice), @"adn": @(channel)}
                completion:^(BOOL success, NSString *errorInfo) {
    // Bid loss reporting result
}];
```

## Swift

```swift
let token = ad.getBiddingToken()
// Send the token to the publisher server. The server returns winnerAdId.
ad.loadBiddingAd(withTokenId: winnerAdId)
```

```swift
ad.biddingSuccess(withSecondInfo: ["ecpm": secondPrice, "adn": channel]) { success, errorInfo in
    // Bid win reporting result
}

ad.biddingFail(withWinInfo: ["ecpm": winPrice, "adn": channel]) { success, errorInfo in
    // Bid loss reporting result
}
```

## Client-Side ADM Data Loading

If the bidding stack already returns ADM JSON directly, you can skip the bidding HTTP request and call:

Objective-C:

```objc
[ad loadBiddingAdWithADMData:admData];
```

Swift:

```swift
ad.loadBiddingAd(withADMData: admData)
```

## Method Ownership

| Method | Banner / App Open / Interstitial / Rewarded | Native |
| --- | --- | --- |
| `getBiddingToken` | Called on the ad object | Called on `ADMNativeAdLoader` |
| `loadBiddingAdWithTokenId:` | Called on the ad object | Called on `ADMNativeAdLoader` |
| `loadBiddingAdWithADMData:` | Called on the ad object | Called on `ADMNativeAdLoader` |
| `biddingSuccessWithSecondInfo:completion:` | Called on the ad object | Called on the `ADMNativeAdObject` returned after successful loading |
| `biddingFailWithWinInfo:completion:` | Called on the ad object | Called on the `ADMNativeAdObject` returned after successful or failed loading |
| `getECPMLevel` / `getPECPM` | Called on the ad object | Called on `ADMNativeAdObject` |
| `responseInfo` | Supported by App Open, Interstitial, and Rewarded; Banner does not provide this property | Not provided by Native Loader |

## Banner Refresh

Standard Banner ads can be refreshed automatically by the SDK. In S2S Bidding scenarios, obtain a new token and complete server-side bidding again before refreshing, then call `loadBiddingAdWithTokenId:`. Do not reuse an old token or old `adid`.

## Bidding API Fields

The specific URL, authentication method, and complete field definitions are subject to the server-side API documentation provided by the AdMaster platform or business team. Common fields are listed below.

### Request

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `token` | string | Yes | Encrypted string returned by SDK `getBiddingToken`. |

### Response

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `req_id` / `reqid` | string | Yes | Request ID. |
| `bid_id` / `bidid` | string | Yes | Current bidding ID. |
| `status` | int32 | Yes | `0` indicates success. Other values indicate failure. |
| `bids` | array | No | List of participating bids. |

### `bids` Element

| Field | Type | Description |
| --- | --- | --- |
| `price` | int32 | Bid price. The unit is defined by the server-side API. |
| `adid` | string | Parameter passed to SDK `loadBiddingAdWithTokenId:` after winning. |
| `nurl` | string[] | Bid win notification URL. |
| `lurl` | string[] | Bid loss notification URL. |
| `is_price_enc` | string | `1` indicates that the price is encrypted in transmission. |
| `end_bid_price` | string | Encrypted price. |
| `cur` | string | Currency. |
