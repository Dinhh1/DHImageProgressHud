//
//  DHImageProgressHud.h
//
//  Created by Dinh Ho on 10/15/14.
//  Copyright (c) 2014 Dinh Ho. All rights reserved.

// GITHUB: https://github.com/Dinhh1/DHImageProgressHud

// DHImageProgressHud was adapted from SVProgressHud originally developed by Sam Vermette https://github.com/TransitApp/SVProgressHUD
//


#import <UIKit/UIKit.h>
#import <AvailabilityMacros.h>

extern NSString * const DHImageProgressHudDidReceiveTouchEventNotification;
extern NSString * const DHImageProgressHudWillDisappearNotification;
extern NSString * const DHImageProgressHudDidDisappearNotification;
extern NSString * const DHImageProgressHudWillAppearNotification;
extern NSString * const DHImageProgressHudDidAppearNotification;

extern NSString * const DHImageProgressHudStatusUserInfoKey;

typedef NS_ENUM(NSUInteger, DHImageProgressHudType) {
    DHImageProgressHudTypeNone = 1, // allow user interactions while HUD is displayed
    DHImageProgressHudTypeClear, // don't allow
    DHImageProgressHudTypeBlack, // don't allow and dim the UI in the back of the HUD
    DHImageProgressHudTypeCustomColor, // allow the user to specify the customer color, the user must call setProgressHudCustomMaskColor to set the color
    DHImageProgressHudTypeGradient // don't allow and dim the UI with a a-la-alert-view bg gradient
};

@interface DHImageProgressHud : UIView

#pragma mark - Customization
/**
 Sets the background color of the loading view
 The default color is [UIColor whiteColor]
 @param color: the color to set the background
 */
+ (void)setBackgroundColor:(UIColor*)color;

/**
 Sets the foreground color of the loading view
 The default color is [UIColor blacColor]
 @param color: the color to set the foreground
 */
+ (void)setForegroundColor:(UIColor*)color;

/**
 Sets the font for the the text string
 The default font is [UIFont systemFont]
 @param font: the desired font
 */
+ (void)setFont:(UIFont*)font; // default is [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
+ (void)setSuccessImage:(UIImage*)image; // default is bundled success image from Glyphish
+ (void)setErrorImage:(UIImage*)image; // default is bundled error image from Glyphish
+ (void)setAnimationImagePrefix:(NSString *)imagePrefix numOfFrames:(NSInteger)frames;
+ (void)setProgressHudCustomMaskColor:(UIColor *)color; // default is [UIColor clearColor];

#pragma mark - Show Methods

+ (void)show;
+ (void)showWithMaskType:(DHImageProgressHudType)maskType;
+ (void)showWithStatus:(NSString*)status;
+ (void)showWithStatus:(NSString*)status maskType:(DHImageProgressHudType)maskType;

+ (void)setStatus:(NSString*)string; // change the HUD loading status while it's showing

// stops the activity indicator, shows a glyph + status, and dismisses HUD 1s later
+ (void)showSuccessWithStatus:(NSString*)string;
+ (void)showErrorWithStatus:(NSString *)string;
+ (void)showImage:(UIImage*)image status:(NSString*)status; // use 28x28 white pngs

+ (void)setOffsetFromCenter:(UIOffset)offset;
+ (void)resetOffsetFromCenter;

+ (void)popActivity;
+ (void)dismiss;

+ (BOOL)isVisible;

@end

