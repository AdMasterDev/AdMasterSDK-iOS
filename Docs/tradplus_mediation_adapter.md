# AdMaster SDK — TradPlus Mediation Custom Adapter Guide (iOS)

This guide explains how to integrate **AdMaster SDK** via **TradPlus Mediation (Custom Network)** in iOS apps, supporting **Banner**, **Interstitial**, **Rewarded Video**, **Splash**, and **Native (Self-Render / Template)** formats with both **Waterfall** and **C2S In-App Header Bidding** (including win-cache reuse).

---

## 1. Version and Environment Requirements

| Component | Requirement |
| --- | --- |
| **Minimum iOS Version** | iOS 12.0+ |
| **AdMasterSDK** | `>= 2.1.0` |
| **TradPlusMediationAdMaster** | `2.1.0.0` |
| **TradPlusAdSDK** | TradPlus iOS SDK (`>= 15.7.0`) |

---

## 2. CocoaPods Integration

Add the following dependencies to your `Podfile`:

```ruby
platform :ios, '12.0'

target 'YourAppTarget' do
  use_frameworks!

  # 1. AdMaster Core SDK
  pod 'AdMasterSDK', '~> 2.1.0'

  # 2. TradPlus Core SDK
  pod 'TradPlusAdSDK', '>= 15.7.0'

  # 3. AdMaster TradPlus Custom Adapter
  pod 'TradPlusMediationAdMaster', '~> 2.1.0.0'
end
```

Run `pod install --repo-update`. If integrating source files manually, ensure all `.h/.m` files under `Mediation/TradPlus/` are added to your target and `-ObjC` is included in **Build Settings -> Other Linker Flags**.

---

## 3. TradPlus Dashboard Custom Network Configuration

### 1. Adapter Class Names

When adding a Custom Network in the TradPlus Dashboard, configure the Adapter class name for each format (both `ADMTradPlus*Adapter` and `TradPlusAdMaster*Adapter` aliases are provided):

| Ad Format | Primary Adapter Class | Alias Adapter Class |
| --- | --- | --- |
| **Banner** | `ADMTradPlusBannerAdapter` | `TradPlusAdMasterBannerAdapter` |
| **Interstitial** | `ADMTradPlusInterstitialAdapter` | `TradPlusAdMasterInterstitialAdapter` |
| **Rewarded Video** | `ADMTradPlusRewardedAdapter` | `TradPlusAdMasterRewardedAdapter` |
| **Splash** | `ADMTradPlusSplashAdapter` | `TradPlusAdMasterSplashAdapter` |
| **Native** | `ADMTradPlusNativeAdapter` | `TradPlusAdMasterNativeAdapter` |

### 2. Server Parameters JSON

Configure server parameters in the TradPlus Dashboard as JSON:

```json
{
  "app_id": "YOUR_ADMASTER_APP_ID",
  "placement_id": "YOUR_ADMASTER_SLOT_ID",
  "bid_floor": 100
}
```

| Parameter | Aliases | Type | Required | Description |
| --- | --- | --- | --- | --- |
| `app_id` | `appId`, `appsid` | String | Yes | AdMaster App ID (`appsid`). |
| `placement_id` | `placementId`, `slot_id`, `slotId`, `ad_unit_id`, `unit_id` | String | Yes | AdMaster placement ID (`adUnitTag`). |
| `bid_floor` | `ecpm` | Number / String | No | Floor price in cents (e.g., `100` = 1.00). |
| `ad_width` | `width` | Number | No | Ad width in pt (for Banner / Splash / Native video container). |
| `ad_height` | `height` | Number | No | Ad height in pt. |
| `is_muted` | - | Bool / String | No | Mute video playback (default `true`). |
| `user_id` | - | String | No | Rewarded video server-side verification user ID. |
| `extra_info` | `custom_data`, `custom_ext` | String / Object | No | Rewarded video custom payload or JSON parameters. |
| `test_mode` | `test` | Bool / String | No | Enable test traffic (`true`/`false`). |
| `mock_mode` | `mock` | Bool / String | No | Enable mock ads (`true`/`false`). |

---

## 4. C2S Header Bidding Workflow

1. **Enable C2S Bidding**: Set the custom ad source to **C2S Bidding** in the TradPlus Dashboard.
2. **Bidding Request (`getC2SBiddingWithWaterfallItem:` / `startBiddingRequestWithInfo:localInfo:completion:`)**:
   - The adapter initializes `ADMManager` and loads the corresponding AdMaster ad instance.
   - After the ad loads, it reads the real-time eCPM in cents via `[ad getECPMLevel]`, reports it to TradPlus via `[self finishC2SBiddingWithEcpm:]`, and caches the ready ad object inside the adapter.
3. **Cache Reuse on Win (`loadAdWithWaterfallItem:`)**:
   - When TradPlus notifies the same adapter instance of a bid win via `loadAdWithWaterfallItem:`, the adapter reuses the cached ad object immediately and invokes `[self AdLoaded]` without making a second network request.
4. **Bid Win/Loss Notification & Idempotency (`ADMTradPlusBiddingNotice`)**:
   - **Win (`biddingSuccessWithSecondInfo:` / `notifyBidWinWithPrice:secondPrice:extra:`)**: Forwards second-price and winner info to AdMaster SDK.
   - **Loss (`biddingFailWithWinInfo:` / `notifyBidLossWithLossType:winPrice:extra:`)**: Maps TradPlus loss reasons to AdMaster codes (`100` = timeout, `203` = low price, `900` = other) and reports them.
   - **Idempotency (First-Terminal-Wins)**: Each `ADMTradPlusBiddingNotice` instance ensures at most one terminal win/loss notification is fired.

---

## 5. Ad Format Usage

### 1. Banner
- Once loaded, `adapter.customAdObj` and `asset[@"adView"]` hold the `ADMBannerView *` instance.
- Default size is `320x50`, customizable via `ad_width` / `ad_height`.

### 2. Interstitial
- Present using `[adapter showAdFromRootViewController:viewController]` or `[adapter showInterstitialFromViewController:viewController]`.

### 3. Rewarded Video
- Supports `user_id` and `extra_info` for server-side reward verification.
- Present using `[adapter showAdFromRootViewController:viewController]` or `[adapter showRewardedVideoFromViewController:viewController]`.
- Triggers `AdRewardedWithInfo:` and `tradPlusAdapterDidReward:extra:` once per display when reward criteria are met.

### 4. Splash
- Present using `[adapter showAdInWindow:window bottomView:bottomView]` or `[adapter showSplashInContainerView:containerView viewController:viewController]`.
- Skip and countdown completion converge to a single `AdClose` callback.

### 5. Native
- `adapter.customAdObj` holds an `ADMTradPlusNativeAd *` wrapper exposing `title`, `mainText`, `ctaText`, `advertiserName`, `iconImageURLString`, `mainImageURLString`, `imageURLList`, `videoURLString`, `isVideoAd`, `isExpressAd`, and `mediaView`.
- After rendering, call `[nativeAd registerContainer:containerView withClickableViews:clickableViews viewController:viewController]` to bind impressions and clicks, and call `[nativeAd unregisterView]` or `[adapter destroy]` on teardown.

---

## 6. Error Code Mapping

The adapter uses error domain `cc.admaster.mediation.tradplus` and maps AdMaster SDK error codes as follows:

| Error Code | Enum | Scenario |
| --- | --- | --- |
| `-4001` | `ADMTradPlusErrorCodeInvalidParameters` | Missing `app_id` / `placement_id` or invalid AdMaster request parameters (`1010001..1049999`, `4000..4999`, `4010001..4999999`) |
| `-4002` | `ADMTradPlusErrorCodeSDKInitFailed` | `ADMManager` initialization failure |
| `-4003` | `ADMTradPlusErrorCodeAdLoadFailed` | General ad load failure fallback |
| `-4004` | `ADMTradPlusErrorCodeAdNotReady` | Ad not ready or expired at presentation time |
| `-4005` | `ADMTradPlusErrorCodeAdPresentFailed` | Presentation / rendering failure (`3040001..3040003`) |
| `-4006` | `ADMTradPlusErrorCodeBiddingFailed` | Invalid C2S bidding price (`eCPM <= 0`) |
| `-4007` | `ADMTradPlusErrorCodeNoFill` | No fill or parsing filter (`1000..3999`, `3010001..3040000`) |
