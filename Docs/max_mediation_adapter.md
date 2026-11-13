# AppLovin MAX Mediation Adapter

`MAXMediationAdMaster` is the AppLovin MAX custom SDK network adapter for AdMaster SDK. After installing the Pod, most integration work is completed in the MAX Dashboard.

## CocoaPods

Add the following dependency to the app target's `Podfile`:

```ruby
pod 'MAXMediationAdMaster'
```

Run:

```bash
pod install --repo-update
```

This Pod depends on `AppLovinSDK` and `AdMasterSDK`. You do not need to add the main SDK Pod separately.

## MAX Dashboard Configuration

Official configuration reference: [Preparing mediated networks](https://support.axon.ai/en/max/ios/preparing-mediated-networks).

Create a Custom Network in the MAX Dashboard:

| Item | Value |
| --- | --- |
| Network Type | SDK |
| iOS Adapter Class Name | `ALAdMasterMediationAdapter` |

Recommended Server Parameters:

```json
{
  "app_id": "your_app_id",
  "ad_unit_id": "your_ad_unit_id",
  "test": false,
  "mock": false
}
```

| Field | Required | Description |
| --- | --- | --- |
| `app_id` | Yes | AdMaster App ID used to initialize the SDK. |
| `ad_unit_id` | No | AdMaster ad placement ID. You can also use the MAX Third-party Placement ID. |
| `test` | No | Marks requests as test traffic. Do not enable this in Release builds. |
| `mock` | No | Uses fixed test ads. Do not enable this in Release builds. |
| `width` / `height` | No | Banner / MREC size. |
| `banner_width` / `banner_height` | No | Banner / MREC size. Takes priority over `width` / `height`. |
| `bid_floor` | No | Bidding floor price in cents (positive integer), passed to `ADMRequest.bidFloor`. |

Configuration flow:

1. In the MAX Dashboard, create or select a Custom SDK Network.
2. Set iOS Adapter Class Name to `ALAdMasterMediationAdapter`.
3. Configure the Third-party Placement ID or Server Parameters for the target ad unit / placement.
4. Install `MAXMediationAdMaster` with CocoaPods and do not change the adapter class name.

## Supported Ad Formats

- App Open (Waterfall + Bidding)
- Banner / Leader / MREC (Waterfall + Bidding)
- Interstitial (Waterfall + Bidding)
- Rewarded (Waterfall + Bidding)
- Native (Waterfall + Bidding)

## Bidding and Win/Loss Reporting

- **Signal Collection**: `ALAdMasterMediationAdapter` conforms to `MAAdapterSignalCollectionProvider` and implements `-collectSignalWithParameters:andNotify:` to collect a bidding token via AdMaster SDK's `getBiddingToken` based on `parameters.adFormat`.
- **Bidding Ad Loading**: When `parameters.bidResponse` is non-empty, the adapter automatically enters Bidding mode:
  - If `bidResponse` is an ADM JSON payload (starts with `{`), it calls `loadBiddingAdWithADMData:`.
  - If `bidResponse` is a bidding token / `adid`, it calls `loadBiddingAdWithTokenId:`.
- **Automatic `bidWin` / `bidLoss` Reporting**:
  - In Bidding mode, when an ad loads or is displayed, the adapter automatically builds second-price parameters and calls `biddingSuccessWithSecondInfo:completion:` (idempotent within a single ad lifecycle).
  - When loading fails, the ad expires, or presentation fails (before win is reported), the adapter maps error codes/reasons and calls `biddingFailWithWinInfo:completion:` (idempotent within a single ad lifecycle).

## Notes

- `app_id` is used to initialize AdMasterSDK. The ad placement is resolved from the MAX Third-party Placement ID first, then from `ad_unit_id` / `placement_id`.
- The adapter supports both Custom SDK Network waterfall mediation and Bidding (`bidResponse`) loads.
- See [error_codes.md](error_codes.md) for AdMaster error codes.
