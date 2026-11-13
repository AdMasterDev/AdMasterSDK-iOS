//
//  ADMTradPlusSDKInitManager.m
//  TradPlusMediationAdMaster
//

#import "ADMTradPlusSDKInitManager.h"
#import "ADMTradPlusConstants.h"
#import "ADMTradPlusUtils.h"

#if __has_include(<AdMasterSDK/AdMasterSDK.h>)
#import <AdMasterSDK/AdMasterSDK.h>
#else
#import "ADMManager.h"
#import "ADMSetting.h"
#endif

typedef NS_ENUM(NSInteger, ADMTradPlusInitState) {
    ADMTradPlusInitStateNotInitialized = 0,
    ADMTradPlusInitStateInitializing   = 1,
    ADMTradPlusInitStateInitialized    = 2
};

@interface ADMTradPlusSDKInitManager ()

@property (nonatomic, assign) ADMTradPlusInitState state;
@property (nonatomic, copy, readwrite, nullable) NSString *initializedAppID;
@property (nonatomic, strong) NSMutableArray<ADMTradPlusInitCompletion> *pendingCallbacks;

@end

@implementation ADMTradPlusSDKInitManager

+ (instancetype)sharedInstance {
    static ADMTradPlusSDKInitManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ADMTradPlusSDKInitManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _state = ADMTradPlusInitStateNotInitialized;
        _pendingCallbacks = [NSMutableArray array];
    }
    return self;
}

- (BOOL)isInitialized {
    @synchronized (self) {
        return self.state == ADMTradPlusInitStateInitialized;
    }
}

- (void)initializeSDKWithServerExtra:(NSDictionary *)serverExtra
                          localExtra:(NSDictionary *)localExtra
                          completion:(ADMTradPlusInitCompletion)completion {
    NSString *appID = [ADMTradPlusUtils appIDFromServerExtra:serverExtra localExtra:localExtra];
    [self initializeSDKWithAppID:appID
                     serverExtra:serverExtra
                      localExtra:localExtra
                      completion:completion];
}

- (void)initializeSDKWithAppID:(NSString *)appID
                   serverExtra:(NSDictionary *)serverExtra
                    localExtra:(NSDictionary *)localExtra
                    completion:(ADMTradPlusInitCompletion)completion {
    if (!completion) {
        completion = ^(BOOL s, NSError *e) {};
    }

    [ADMTradPlusUtils updateAdMasterRuntimeFromServerExtra:serverExtra localExtra:localExtra];

    NSCharacterSet *wsSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *trimmedAppID = [appID isKindOfClass:[NSString class]] ? [appID stringByTrimmingCharactersInSet:wsSet] : nil;

    if (trimmedAppID.length == 0) {
        NSError *err = [ADMTradPlusUtils errorWithCode:ADMTradPlusErrorCodeInvalidParameters
                                           description:@"Missing AdMaster app_id in TradPlus configuration"];
        [ADMTradPlusUtils dispatchOnMainThread:^{
            completion(NO, err);
        }];
        return;
    }

    @synchronized (self) {
        if (self.state == ADMTradPlusInitStateInitialized) {
            [ADMTradPlusUtils dispatchOnMainThread:^{
                completion(YES, nil);
            }];
            return;
        }

        [self.pendingCallbacks addObject:[completion copy]];
        if (self.state == ADMTradPlusInitStateInitializing) {
            return;
        }
        self.state = ADMTradPlusInitStateInitializing;
    }

    [ADMTradPlusUtils dispatchOnMainThread:^{
        __weak typeof(self) weakSelf = self;
        [ADMManager startWithAppsid:trimmedAppID completionHandler:^(BOOL success, NSError *_Nullable error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            NSArray<ADMTradPlusInitCompletion> *callbacks = nil;
            NSError *wrappedError = nil;
            @synchronized (strongSelf) {
                if (success) {
                    strongSelf.state = ADMTradPlusInitStateInitialized;
                    strongSelf.initializedAppID = trimmedAppID;
                } else {
                    strongSelf.state = ADMTradPlusInitStateNotInitialized;
                    wrappedError = [ADMTradPlusUtils errorFromADMError:error
                                                           defaultCode:ADMTradPlusErrorCodeSDKInitFailed
                                                    defaultDescription:@"AdMaster SDK initialization failed"];
                }
                callbacks = [strongSelf.pendingCallbacks copy];
                [strongSelf.pendingCallbacks removeAllObjects];
            }

            [ADMTradPlusUtils dispatchOnMainThread:^{
                for (ADMTradPlusInitCompletion cb in callbacks) {
                    cb(success, wrappedError);
                }
            }];
        }];
    }];
}

- (void)resetForTesting {
    @synchronized (self) {
        self.state = ADMTradPlusInitStateNotInitialized;
        self.initializedAppID = nil;
        [self.pendingCallbacks removeAllObjects];
    }
}

@end
