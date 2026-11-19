//
//  ADMTradPlusConstants.h
//  TradPlusMediationAdMaster
//
//  Constants and error codes for AdMaster TradPlus Custom Adapter.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Error domain for AdMaster TradPlus Mediation Adapter
static NSString *const ADMTradPlusErrorDomain = @"cc.admaster.mediation.tradplus";

/// Adapter version: <AdMaster SDK version>.<adapter patch version>
static NSString *const ADMTradPlusAdapterVersion = @"2.2.0.0";

/// Network name for TradPlus reporting
static NSString *const ADMTradPlusNetworkName = @"MediaGo";

#pragma mark - Server / Local Parameter Keys

/// App ID keys (Configured in TradPlus dashboard -> Custom Network -> Server Parameters)
static NSString *const ADMTradPlusParamAppID = @"app_id";
static NSString *const ADMTradPlusParamAppIDCamel = @"appId";
static NSString *const ADMTradPlusParamAppSID = @"appsid";

/// Placement / Slot / AdUnit ID keys
static NSString *const ADMTradPlusParamPlacementID = @"placement_id";
static NSString *const ADMTradPlusParamPlacementIDCamel = @"placementId";
static NSString *const ADMTradPlusParamSlotID = @"slot_id";
static NSString *const ADMTradPlusParamSlotIDCamel = @"slotId";
static NSString *const ADMTradPlusParamAdUnitID = @"ad_unit_id";
static NSString *const ADMTradPlusParamUnitID = @"unit_id";

/// Bidding & Floor Price keys
static NSString *const ADMTradPlusParamECPM = @"ecpm";
static NSString *const ADMTradPlusParamBidFloor = @"bid_floor";
static NSString *const ADMTradPlusParamADMPayload = @"adm_payload";
static NSString *const ADMTradPlusParamTokenID = @"token_id";

/// Ad Size & Media Configuration keys
static NSString *const ADMTradPlusParamAdWidth = @"ad_width";
static NSString *const ADMTradPlusParamAdHeight = @"ad_height";
static NSString *const ADMTradPlusParamWidth = @"width";
static NSString *const ADMTradPlusParamHeight = @"height";
static NSString *const ADMTradPlusParamIsMuted = @"is_muted";

/// Rewarded & Custom Extension keys
static NSString *const ADMTradPlusParamUserID = @"user_id";
static NSString *const ADMTradPlusParamExtraInfo = @"extra_info";
static NSString *const ADMTradPlusParamCustomExt = @"custom_ext";
static NSString *const ADMTradPlusParamCustomData = @"custom_data";

/// Test / Mock Mode keys
static NSString *const ADMTradPlusParamTestMode = @"test_mode";
static NSString *const ADMTradPlusParamTest = @"test";
static NSString *const ADMTradPlusParamMockMode = @"mock_mode";
static NSString *const ADMTradPlusParamMock = @"mock";

/// TradPlus C2S Bidding Win / Loss Notification keys
static NSString *const ADMTradPlusParamWinPrice = @"win_price";
static NSString *const ADMTradPlusParamSecondPrice = @"second_price";
static NSString *const ADMTradPlusParamLossReason = @"loss_reason";
static NSString *const ADMTradPlusParamAdnID = @"adn_id";

/// TradPlus Waterfall extraInfoDictionary keys
static NSString *const ADMTradPlusExtraLocalParams = @"localParams";
static NSString *const ADMTradPlusExtraRootViewController = @"root_view_controller";
static NSString *const ADMTradPlusExtraWindow = @"window";
static NSString *const ADMTradPlusExtraBottomView = @"bottom_view";

#pragma mark - Adapter Error Codes

typedef NS_ENUM(NSInteger, ADMTradPlusErrorCode) {
    ADMTradPlusErrorCodeInvalidParameters = -4001,
    ADMTradPlusErrorCodeSDKInitFailed = -4002,
    ADMTradPlusErrorCodeAdLoadFailed = -4003,
    ADMTradPlusErrorCodeAdNotReady = -4004,
    ADMTradPlusErrorCodeAdPresentFailed = -4005,
    ADMTradPlusErrorCodeBiddingFailed = -4006,
    ADMTradPlusErrorCodeNoFill = -4007,
};

NS_ASSUME_NONNULL_END
