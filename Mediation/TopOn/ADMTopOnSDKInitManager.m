#import "ADMTopOnSDKInitManager.h"
#import "ADMTopOnUtils.h"
#import "ADMTopOnConstants.h"

#if __has_include(<AdMasterSDK/AdMasterSDK.h>)
#import <AdMasterSDK/AdMasterSDK.h>
#else
#import "ADMManager.h"
#endif

@interface ADMTopOnSDKInitManager ()

@property (nonatomic, assign, readwrite) BOOL isInitialized;
@property (nonatomic, assign) BOOL isInitializing;
@property (nonatomic, copy, readwrite, nullable) NSString *initializedAppID;
@property (nonatomic, strong) NSMutableArray<ADMTopOnSDKInitCompletion> *pendingCompletions;

@end

@implementation ADMTopOnSDKInitManager

+ (instancetype)sharedInstance {
    static ADMTopOnSDKInitManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ADMTopOnSDKInitManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _isInitialized = NO;
        _isInitializing = NO;
        _initializedAppID = nil;
        _pendingCompletions = [NSMutableArray array];
    }
    return self;
}

+ (NSString *)sdkVersion {
    NSString *ver = [ADMManager getSDKVersion];
    return ver.length > 0 ? ver : @"";
}

+ (NSString *)adapterVersion {
    return ADMTopOnAdapterVersion;
}

- (void)initSDKWithAppID:(nullable NSString *)appID
             serverExtra:(nullable NSDictionary *)serverExtra
              localExtra:(nullable NSDictionary *)localExtra
              completion:(ADMTopOnSDKInitCompletion)completion {
    NSString *resolvedAppID = nil;
    if ([appID isKindOfClass:[NSString class]]) {
        NSString *trimmed = [appID stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimmed.length > 0) {
            resolvedAppID = trimmed;
        }
    }
    if (resolvedAppID.length == 0) {
        resolvedAppID = [ADMTopOnUtils appIDFromServerExtra:serverExtra localExtra:localExtra];
    }

    if (resolvedAppID.length == 0) {
        NSError *paramError = [ADMTopOnUtils errorWithCode:ADMTopOnErrorCodeInvalidParameters
                                               description:@"Missing app_id for AdMaster TopOn adapter initialization."];
        [ADMTopOnUtils dispatchOnMainThread:^{
            if (completion) {
                completion(NO, paramError);
            }
        }];
        return;
    }

    [ADMTopOnUtils updateAdMasterRuntimeFromServerExtra:serverExtra localExtra:localExtra];

    @synchronized (self) {
        if (self.isInitialized) {
            [ADMTopOnUtils dispatchOnMainThread:^{
                if (completion) {
                    completion(YES, nil);
                }
            }];
            return;
        }
        if (completion) {
            [self.pendingCompletions addObject:[completion copy]];
        }
        if (self.isInitializing) {
            return;
        }
        self.isInitializing = YES;
    }

    [ADMManager startWithAppsid:resolvedAppID completionHandler:^(BOOL success, NSError *_Nullable error) {
        NSArray<ADMTopOnSDKInitCompletion> *callbacks = nil;
        NSError *callbackError = nil;

        @synchronized (self) {
            self.isInitializing = NO;
            if (success) {
                self.isInitialized = YES;
                self.initializedAppID = [resolvedAppID copy];
            } else {
                self.isInitialized = NO;
                self.initializedAppID = nil;
                NSString *rawDesc = error.localizedDescription;
                NSString *desc = rawDesc.length > 0 ? rawDesc : @"AdMaster SDK initialization failed.";
                callbackError = [ADMTopOnUtils errorWithCode:ADMTopOnErrorCodeSDKInitFailed
                                                 description:desc];
            }
            callbacks = [self.pendingCompletions copy];
            [self.pendingCompletions removeAllObjects];
        }

        [ADMTopOnUtils dispatchOnMainThread:^{
            for (ADMTopOnSDKInitCompletion cb in callbacks) {
                cb(success, callbackError);
            }
        }];
    }];
}

- (void)resetForTesting {
    @synchronized (self) {
        self.isInitialized = NO;
        self.isInitializing = NO;
        self.initializedAppID = nil;
        [self.pendingCompletions removeAllObjects];
    }
}

@end
