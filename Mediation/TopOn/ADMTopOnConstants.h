#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// TopOn AnyThink Adapter 版本号（四段式，前三位对齐 AdMasterSDK 版本）
static NSString *const ADMTopOnAdapterVersion = @"2.1.0.0";

/// 广告网络名称
static NSString *const ADMTopOnNetworkName = @"MediaGo";

/// 错误域
static NSString *const ADMTopOnErrorDomain = @"com.admaster.mediation.topon";

/// 服务端/本地配置参数 Key
static NSString *const ADMTopOnParamKeyAppID = @"app_id";
static NSString *const ADMTopOnParamKeyPlacementID = @"placement_id";
static NSString *const ADMTopOnParamKeyAdUnitID = @"ad_unit_id";
static NSString *const ADMTopOnParamKeyUnitID = @"unit_id";
static NSString *const ADMTopOnParamKeySlotID = @"slot_id";
static NSString *const ADMTopOnParamKeyCustomExt = @"custom_ext";
static NSString *const ADMTopOnParamKeyBidFloor = @"bid_floor";
static NSString *const ADMTopOnParamKeyTest = @"test";
static NSString *const ADMTopOnParamKeyMock = @"mock";
static NSString *const ADMTopOnParamKeyUnitType = @"unit_type";
static NSString *const ADMTopOnParamKeyAdWidth = @"ad_width";
static NSString *const ADMTopOnParamKeyAdHeight = @"ad_height";
static NSString *const ADMTopOnParamKeyWidth = @"width";
static NSString *const ADMTopOnParamKeyHeight = @"height";
static NSString *const ADMTopOnParamKeyUserID = @"user_id";
static NSString *const ADMTopOnParamKeyCustomData = @"custom_data";

/// TopOn Adapter 错误码定义
typedef NS_ENUM(NSInteger, ADMTopOnErrorCode) {
    ADMTopOnErrorCodeInvalidParameters = 30001,
    ADMTopOnErrorCodeSDKInitFailed = 30002,
    ADMTopOnErrorCodeAdLoadFailed = 30003,
    ADMTopOnErrorCodeAdNotReady = 30004,
    ADMTopOnErrorCodeAdPresentFailed = 30005,
    ADMTopOnErrorCodeInvalidContainer = 30006
};

NS_ASSUME_NONNULL_END
