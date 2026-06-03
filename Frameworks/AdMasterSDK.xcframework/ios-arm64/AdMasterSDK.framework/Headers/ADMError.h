//
//  ADMError.h
//  AdMasterSDK
//

#ifndef ADMError_h
#define ADMError_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Public NSError domain for delegate / mediation callbacks.
#define ADMPublicErrorDomain @"cc.admaster.sdk.public.ErrorDomain"

#ifndef ADMErrorDomain
#define ADMErrorDomain ADMPublicErrorDomain
#endif

/// userInfo key for native visibility check failures (not a server code).
FOUNDATION_EXPORT NSString *const ADMVisibilityFailCodeKey;

/// userInfo key carrying the raw player/media playback error code (not a server code).
FOUNDATION_EXPORT NSString *const ADMPlaybackErrorCodeKey;

/// userInfo key carrying SDK/client-side diagnostic error codes (not a server code).
FOUNDATION_EXPORT NSString *const ADMClientErrorCodeKey;

typedef NS_ENUM(NSInteger, ADMErrorCode) {
    // Load failures
    ADMErrorCodeNoFill          = 1001, // No ad returned from server
    ADMErrorCodeNetworkError    = 1002, // Network or server exception
    ADMErrorCodeInvalidConfig   = 1003, // Invalid placement ID / app ID

    // Cache / download failures
    ADMErrorCodeDownloadFailed  = 2001, // Video asset download failed
    ADMErrorCodeCacheFailed     = 2002, // Video cache failed

    // Display / show failures
    ADMErrorCodeInvalidContent  = 3001, // Ad content or dimensions invalid
    ADMErrorCodeShowFailed      = 3002, // Generic presentation failure

    // Playback failures
    ADMErrorCodePlaybackFailed  = 4001, // Video playback error
};

/// userInfo key carrying the raw server error code string (e.g. @"4001")
FOUNDATION_EXPORT NSString *const ADMServerErrorCodeKey;

@interface NSError (ADMError)

+ (NSError *)adm_errorWithCode:(ADMErrorCode)code
                    serverCode:(nullable NSString *)serverCode
                       message:(nullable NSString *)message;

+ (NSError *)adm_errorWithCode:(ADMErrorCode)code
               clientErrorCode:(nullable NSString *)clientErrorCode
                       message:(nullable NSString *)message;

/// Build an NSError from a server-returned error code string.
/// Looks up the curated description table and infers the semantic ADMErrorCode
/// (NoFill / InvalidConfig / InvalidContent / NetworkError).
+ (NSError *)adm_errorFromServerCode:(nullable NSString *)serverCode
                      fallbackMessage:(nullable NSString *)message;

@end

NS_ASSUME_NONNULL_END

#endif /* ADMError_h */
