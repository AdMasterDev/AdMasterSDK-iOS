# Google Mobile Ads Mediation Adapter

`GADMediationAdMaster` is the Google Mobile Ads Mediation custom event adapter for AdMaster SDK. After installing the Pod, most integration work is completed in the AdMob / Google Ad Manager dashboard.

## CocoaPods

Add the following dependency to the app target's `Podfile`:

```ruby
pod 'GADMediationAdMaster'
```

Run:

```bash
pod install --repo-update
```

This Pod depends on `Google-Mobile-Ads-SDK` and `AdMasterSDK`. You do not need to add the main SDK Pod separately.

## Dashboard Configuration

Official configuration reference: [Set up a custom event](https://support.google.com/admob/answer/13407144).

Create a custom event in the Google Mobile Ads Mediation dashboard and use the following class name for each supported ad format:

| Ad Format | Class Name |
| --- | --- |
| App Open | `ADMCustomEvent` |
| Banner | `ADMCustomEvent` |
| Interstitial | `ADMCustomEvent` |
| Rewarded | `ADMCustomEvent` |
| Native | `ADMCustomEvent` |

Set `parameter` to a JSON string:

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
| `ad_unit_id` | Yes | AdMaster ad placement ID. |
| `test` | No | Marks requests as test traffic. Do not enable this in Release builds. |
| `mock` | No | Uses fixed test ads. Do not enable this in Release builds. |

Configuration flow:

1. In the AdMob dashboard, go to Mediation, open Waterfall sources, and add a Custom Event.
2. Add a mapping, then set the mapping name, Class Name, and `parameter`.
3. Add the Custom Event to the target Mediation Group and configure a manual eCPM.
4. Make sure the Class Name and `parameter` configured in the dashboard match the adapter integrated in the app.

## Notes

- The adapter initializes AdMasterSDK with `app_id` and loads ads with `ad_unit_id`.
- Loading, presentation, impression, click, close, and reward events are mapped to Google Mobile Ads Mediation callbacks by the adapter.
- See [error_codes.md](error_codes.md) for AdMaster error codes.
