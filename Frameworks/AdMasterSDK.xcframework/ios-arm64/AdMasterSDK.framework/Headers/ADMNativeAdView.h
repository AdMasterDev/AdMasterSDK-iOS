//
//  ADMNativeAdView.h
//  AdMasterSDK
//
//  Created by lishan04 on 15-1-6.
//
//

#ifndef ADMNativeAdView_h
#define ADMNativeAdView_h

#import <UIKit/UIKit.h>
#import <AdMasterSDK/ADMCommonConfig.h>
@class ADMNativeVideoView;
@class ADMNativeAdObject;
@class ADMNativeWebView;
@class ADMAdActButton;
@interface ADMNativeAdView : UIView

/**
 * Icon image view.
 */
@property (strong, nonatomic) UIImageView *iconImageView;

/**
 * Main image view.
 */
@property (strong, nonatomic) UIImageView *mainImageView;

/**
 * Multi-image views.
 */
@property (strong, nonatomic) NSMutableArray *morePicsArray;

/**
 * Ad disclosure badge.
 */
@property (strong, nonatomic) UIImageView *adLogoImageView;

/**
 * Network logo.
 */
@property (strong, nonatomic) UIImageView *admLogoImageView;

/**
 * Title label.
 */
@property (strong, nonatomic) UILabel *titleLabel;

/**
 * Description label.
 */
@property (strong, nonatomic) UILabel *textLabel;

/**
 * Brand name label.
 */
@property (strong, nonatomic) UILabel *brandLabel;

/**
 * CTA button.
 */
@property (strong, nonatomic) ADMAdActButton *actButton;

/**
 * Video view.
 */
@property (strong, nonatomic) ADMNativeVideoView *videoView;

/**
 * Web view (template ads).
 */
@property (strong, nonatomic) ADMNativeWebView *webView;


/**
 * Close button.
 */
@property (strong, nonatomic) UIButton *closeButton;

/**
 * View controller for landing page (optional).
 */
@property (nonatomic, weak) UIViewController *presentAdViewController;

/**
 * Bound ad object.
 */
@property (nonatomic, strong, readonly) ADMNativeAdObject *object;

/**
 * Standard large-image native ad initializer (ADMMaterialType NORMAL).
 *
 * @param frame View size
 * @param brandLabel Brand label
 * @param titleLabel Title label
 * @param textLabel Description label
 * @param iconView Icon view
 * @param mainView Main image view
 * @return Native ad view
 */
- (instancetype)initWithFrame:(CGRect)frame
          brandName:(UILabel *)brandLabel
              title:(UILabel *)titleLabel
               text:(UILabel *)textLabel
               icon:(UIImageView *)iconView
          mainImage:(UIImageView *)mainView;

/**
 * Multi-image native ad initializer (ADMMaterialType NORMAL).
 */
- (instancetype)initWithFrame:(CGRect)frame
          brandName:(UILabel *)brandLabel
              title:(UILabel *)titleLabel
               text:(UILabel *)textLabel
               icon:(UIImageView *)iconView
          mainImage:(UIImageView *)mainView
           morepics:(NSMutableArray *)imageViewArray;

/**
 * Video native ad initializer.
 * Prefer ADMNativeVideoView; custom video views are also supported.
 */
- (instancetype)initWithFrame:(CGRect)frame
          brandName:(UILabel *)brandLabel
              title:(UILabel *)titleLabel
               text:(UILabel *)textLabel
               icon:(UIImageView *)iconView
          videoView:(ADMNativeVideoView *)videoView;

- (instancetype)initWithFrame:(CGRect)frame
          brandName:(UILabel *)brandLabel
              title:(UILabel *)titleLabel
               text:(UILabel *)textLabel
               icon:(UIImageView *)iconView
          mainImage:(UIImageView *)mainView
          videoView:(ADMNativeVideoView *)videoView;
/**
 * Template native ad initializer.
 */
- (instancetype)initWithFrame:(CGRect)frame
            webview:(ADMNativeWebView *) webView;

/**
 * Load and render the native ad.
 */
- (void)loadAndDisplayNativeAdWithObject:(ADMNativeAdObject *)object completion:(ADMViewCompletionBlock)completionBlock;

/**
 * Start video playback manually (Wi‑Fi autoplay only).
 *
 * @return YES if playing, NO otherwise
 */
- (BOOL)render;

@end

#endif /* ADMNativeAdView_h */
