//
//  DHImageProgressHud.m
//
//  Created by Dinh Ho on 10/15/14.
//  Copyright (c) 2014 Dinh Ho. All rights reserved.
//

#if !__has_feature(objc_arc)
#error DHImageProgressHud is ARC only. Either turn on ARC for the project or use -fobjc-arc flag
#endif

#import "DHImageProgressHud.h"
#import <QuartzCore/QuartzCore.h>

NSString * const DHImageProgressHudDidReceiveTouchEventNotification = @"DHImageProgressHudDidReceiveTouchEventNotification";
NSString * const DHImageProgressHudWillDisappearNotification = @"DHImageProgressHudWillDisappearNotification";
NSString * const DHImageProgressHudDidDisappearNotification = @"DHImageProgressHudDidDisappearNotification";
NSString * const DHImageProgressHudWillAppearNotification = @"DHImageProgressHudWillAppearNotification";
NSString * const DHImageProgressHudDidAppearNotification = @"DHImageProgressHudDidAppearNotification";

NSString * const DHImageProgressHudStatusUserInfoKey = @"DHImageProgressHudStatusUserInfoKey";

static UIColor *DHImageProgressHudBackgroundColor;
static UIColor *DHImageProgressHudForegroundColor;
static UIColor *DHImageProgressHudCustomColor;
static UIFont *DHImageProgressHudFont;
static UIImage *DHImageProgressHudSuccessImage;
static UIImage *DHImageProgressHudErrorImage;
static NSString *DHImageProgressHudAnimationPrefix;
static NSInteger DHImageProgressHudAnimationFPS = 3;

static const CGFloat DHImageProgressHudParallaxDepthPoints = 10;

@interface DHImageProgressHud ()

@property (nonatomic, readwrite) DHImageProgressHudType maskType;
@property (nonatomic, strong, readonly) NSTimer *fadeOutTimer;
@property (nonatomic, readonly, getter = isClear) BOOL clear;

@property (nonatomic, strong) UIControl *overlayView;
@property (nonatomic, strong) UIView *hudView;
@property (nonatomic, strong) UILabel *stringLabel;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImageView *indefiniteAnimatedView;

@property (nonatomic, readwrite) NSUInteger activityCount;

@property (nonatomic, readonly) CGFloat visibleKeyboardHeight;
@property (nonatomic, assign) UIOffset offsetFromCenter;

- (void)showWithstatus:(NSString*)string
              maskType:(DHImageProgressHudType)hudMaskType;


- (void)showImage:(UIImage*)image
           status:(NSString*)status
         duration:(NSTimeInterval)duration;

- (void)dismiss;

- (void)setStatus:(NSString*)string;
- (void)registerNotifications;
- (NSDictionary *)notificationUserInfo;
- (void)moveToPoint:(CGPoint)newCenter rotateAngle:(CGFloat)angle;
- (void)positionHUD:(NSNotification*)notification;
- (NSTimeInterval)displayDurationForString:(NSString*)string;

@end


@implementation DHImageProgressHud

+ (DHImageProgressHud *)sharedInstance {
    static dispatch_once_t once;
    static DHImageProgressHud *instance;
    dispatch_once(&once, ^ { instance = [[self alloc] initWithFrame:[[UIScreen mainScreen] bounds]]; });
    return instance;
}

#pragma mark - Setters

+ (void)setStatus:(NSString *)string {
    [[self sharedInstance] setStatus:string];
}

+ (void)setBackgroundColor:(UIColor *)color {
    [self sharedInstance].hudView.backgroundColor = color;
    DHImageProgressHudBackgroundColor = color;
}

+ (void)setForegroundColor:(UIColor *)color {
    [self sharedInstance];
    DHImageProgressHudForegroundColor = color;
}

+ (void)setFont:(UIFont *)font {
    [self sharedInstance];
    DHImageProgressHudFont = font;
}

+ (void)setSuccessImage:(UIImage *)image {
    [self sharedInstance];
    DHImageProgressHudSuccessImage = image;
}

+ (void)setErrorImage:(UIImage *)image {
    [self sharedInstance];
    DHImageProgressHudErrorImage = image;
}

+ (void)setAnimationImagePrefix:(NSString *)imagePrefix withFPS:(NSInteger)fps
{
    [self sharedInstance];
    DHImageProgressHudAnimationPrefix = imagePrefix;
    DHImageProgressHudAnimationFPS = fps;
}

+ (void)setProgressHudCustomMaskColor:(UIColor *)color
{
    [self sharedInstance];
    DHImageProgressHudCustomColor = color;
}

#pragma mark - Show Methods

+ (void)show {
    [[self sharedInstance] showWithstatus:nil maskType:DHImageProgressHudTypeNone];
}

+ (void)showWithStatus:(NSString *)status {
    [[self sharedInstance] showWithstatus:status maskType:DHImageProgressHudTypeNone];
}

+ (void)showWithMaskType:(DHImageProgressHudType)maskType {
    [[self sharedInstance] showWithstatus:nil maskType:maskType];
}

+ (void)showWithStatus:(NSString*)status maskType:(DHImageProgressHudType)maskType {
    [[self sharedInstance] showWithstatus:status maskType:maskType];
}


#pragma mark - Show then dismiss methods

+ (void)showSuccessWithStatus:(NSString *)string {
    [self sharedInstance];
    [self showImage:DHImageProgressHudSuccessImage status:string];
}

+ (void)showErrorWithStatus:(NSString *)string {
    [self sharedInstance];
    [self showImage:DHImageProgressHudErrorImage status:string];
}

+ (void)showImage:(UIImage *)image status:(NSString *)string {
    NSTimeInterval displayInterval = [[DHImageProgressHud sharedInstance] displayDurationForString:string];
    [[self sharedInstance] showImage:image status:string duration:displayInterval];
}


#pragma mark - Dismiss Methods

+ (void)popActivity {
    [self sharedInstance].activityCount--;
    if([self sharedInstance].activityCount == 0)
        [[self sharedInstance] dismiss];
}

+ (void)dismiss {
    if ([self isVisible]) {
        [[self sharedInstance] dismiss];
    }
}


#pragma mark - Offset

+ (void)setOffsetFromCenter:(UIOffset)offset {
    [self sharedInstance].offsetFromCenter = offset;
}

+ (void)resetOffsetFromCenter {
    [self setOffsetFromCenter:UIOffsetZero];
}

#pragma mark - Instance Methods

- (id)initWithFrame:(CGRect)frame {
    
    if ((self = [super initWithFrame:frame])) {
        self.userInteractionEnabled = NO;
        self.backgroundColor = [UIColor clearColor];
        self.alpha = 0;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.activityCount = 0;
        
        DHImageProgressHudBackgroundColor = [UIColor whiteColor];
        DHImageProgressHudForegroundColor = [UIColor blackColor];
        if ([UIFont respondsToSelector:@selector(preferredFontForTextStyle:)]) {
            DHImageProgressHudFont = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        } else {
            DHImageProgressHudFont = [UIFont systemFontOfSize:14.0];
            DHImageProgressHudBackgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
            DHImageProgressHudForegroundColor = [UIColor whiteColor];
        }
        if ([[UIImage class] instancesRespondToSelector:@selector(imageWithRenderingMode:)]) {
            DHImageProgressHudSuccessImage = [[UIImage imageNamed:@"DHImageProgressHud.bundle/success"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            DHImageProgressHudErrorImage = [[UIImage imageNamed:@"DHImageProgressHud.bundle/error"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        } else {
            DHImageProgressHudSuccessImage = [UIImage imageNamed:@"DHImageProgressHud.bundle/success"];
            DHImageProgressHudErrorImage = [UIImage imageNamed:@"DHImageProgressHud.bundle/error"];
        }
        DHImageProgressHudAnimationPrefix = @"coffee";
        DHImageProgressHudCustomColor = [UIColor clearColor];
    }
    
    return self;
}

- (void)drawRect:(CGRect)rect {
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    switch (self.maskType)
    {
            
        case DHImageProgressHudTypeBlack: {
            [[UIColor colorWithWhite:0 alpha:0.5] set];
            CGContextFillRect(context, self.bounds);
            break;
        }
        case DHImageProgressHudTypeCustomColor: {
            [[DHImageProgressHudCustomColor colorWithAlphaComponent:.80f] set];
            CGContextFillRect(context, self.bounds);
            break;
        }
            
        case DHImageProgressHudTypeGradient: {
            
            size_t locationsCount = 2;
            CGFloat locations[2] = {0.0f, 1.0f};
            CGFloat colors[8] = {0.0f,0.0f,0.0f,0.0f,0.0f,0.0f,0.0f,0.75f};
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colors, locations, locationsCount);
            CGColorSpaceRelease(colorSpace);
            
            CGFloat freeHeight = self.bounds.size.height - self.visibleKeyboardHeight;
            
            CGPoint center = CGPointMake(self.bounds.size.width/2, freeHeight/2);
            float radius = MIN(self.bounds.size.width , self.bounds.size.height) ;
            CGContextDrawRadialGradient (context, gradient, center, 0, center, radius, kCGGradientDrawsAfterEndLocation);
            CGGradientRelease(gradient);
            
            break;
        }
    }
}

- (void)updatePosition {
    
    CGFloat hudWidth = 100;
    CGFloat hudHeight = 100;
    CGFloat stringHeightBuffer = 20;
    CGFloat stringAndImageHeightBuffer = 80;
    
    CGFloat stringWidth = 0;
    CGFloat stringHeight = 0;
    CGRect labelRect = CGRectZero;
    
    NSString *string = self.stringLabel.text;
    // False if it's text-only
    BOOL imageUsed = (self.imageView.image) || (self.imageView.hidden);
    
    if(string) {
        CGSize constraintSize = CGSizeMake(200, 300);
        CGRect stringRect;
        if ([string respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
            stringRect = [string boundingRectWithSize:constraintSize
                                              options:(NSStringDrawingUsesFontLeading|NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin)
                                           attributes:@{NSFontAttributeName: self.stringLabel.font}
                                              context:NULL];
        } else {
            CGSize stringSize;
#ifdef __IPHONE_8_0
            stringSize = [string sizeWithAttributes:@{NSFontAttributeName:[UIFont fontWithName:self.stringLabel.font.fontName size:self.stringLabel.font.pointSize]}];
#else
            stringSize = [string sizeWithFont:self.stringLabel.font constrainedToSize:CGSizeMake(200, 300)];
#endif
            stringRect = CGRectMake(0.0f, 0.0f, stringSize.width, stringSize.height);
        }
        stringWidth = stringRect.size.width;
        stringHeight = ceil(stringRect.size.height);
        
        if (imageUsed)
            hudHeight = stringAndImageHeightBuffer + stringHeight;
        else
            hudHeight = stringHeightBuffer + stringHeight;
        
        if(stringWidth > hudWidth)
            hudWidth = ceil(stringWidth/2)*2;
        
        CGFloat labelRectY = imageUsed ? 68 : 9;
        
        if(hudHeight > 100) {
            labelRect = CGRectMake(12, labelRectY, hudWidth, stringHeight);
            hudWidth+=24;
        } else {
            hudWidth+=24;
            labelRect = CGRectMake(0, labelRectY, hudWidth, stringHeight);
        }
    }
    
    self.hudView.bounds = CGRectMake(0, 0, hudWidth, hudHeight);
    
    if(string)
        self.imageView.center = CGPointMake(CGRectGetWidth(self.hudView.bounds)/2, 36);
    else
       	self.imageView.center = CGPointMake(CGRectGetWidth(self.hudView.bounds)/2, CGRectGetHeight(self.hudView.bounds)/2);
    
    self.stringLabel.hidden = NO;
    self.stringLabel.frame = labelRect;
    
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    
    if(string) {
        [self.indefiniteAnimatedView sizeToFit];
        
        CGPoint center = CGPointMake((CGRectGetWidth(self.hudView.bounds)/2), 36);
        self.indefiniteAnimatedView.center = center;
    }
    else {
        [self.indefiniteAnimatedView sizeToFit];
        
        CGPoint center = CGPointMake((CGRectGetWidth(self.hudView.bounds)/2), CGRectGetHeight(self.hudView.bounds)/2);
        self.indefiniteAnimatedView.center = center;
    }
    
    [CATransaction commit];
}

- (void)setStatus:(NSString *)string {
    
    self.stringLabel.text = string;
    [self updatePosition];
    
}

- (void)setFadeOutTimer:(NSTimer *)newTimer {
    
    if(_fadeOutTimer)
        [_fadeOutTimer invalidate], _fadeOutTimer = nil;
    
    if(newTimer)
        _fadeOutTimer = newTimer;
}


- (void)registerNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(positionHUD:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(positionHUD:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(positionHUD:)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(positionHUD:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(positionHUD:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
}


- (NSDictionary *)notificationUserInfo
{
    return (self.stringLabel.text ? @{DHImageProgressHudStatusUserInfoKey : self.stringLabel.text} : nil);
}


- (void)positionHUD:(NSNotification*)notification {
    
    CGFloat keyboardHeight;
    double animationDuration;
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    // no transforms applied to window in iOS 8, but only if compiled with iOS 8 sdk as base sdk, otherwise system supports old rotation logic.
    BOOL ignoreOrientation = NO;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    if ([[NSProcessInfo processInfo] respondsToSelector:@selector(operatingSystemVersion)]) {
        ignoreOrientation = YES;
    }
#endif
    
    if(notification) {
        NSDictionary* keyboardInfo = [notification userInfo];
        CGRect keyboardFrame = [[keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
        animationDuration = [[keyboardInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        
        if(notification.name == UIKeyboardWillShowNotification || notification.name == UIKeyboardDidShowNotification) {
            if(ignoreOrientation || UIInterfaceOrientationIsPortrait(orientation))
                keyboardHeight = keyboardFrame.size.height;
            else
                keyboardHeight = keyboardFrame.size.width;
        } else
            keyboardHeight = 0;
    } else {
        keyboardHeight = self.visibleKeyboardHeight;
    }
    
    CGRect orientationFrame = self.window.bounds;
    CGRect statusBarFrame = [UIApplication sharedApplication].statusBarFrame;
    
    if(!ignoreOrientation && UIInterfaceOrientationIsLandscape(orientation)) {
        float temp = orientationFrame.size.width;
        orientationFrame.size.width = orientationFrame.size.height;
        orientationFrame.size.height = temp;
        
        temp = statusBarFrame.size.width;
        statusBarFrame.size.width = statusBarFrame.size.height;
        statusBarFrame.size.height = temp;
    }
    
    CGFloat activeHeight = orientationFrame.size.height;
    
    if(keyboardHeight > 0)
        activeHeight += statusBarFrame.size.height*2;
    
    activeHeight -= keyboardHeight;
    CGFloat posY = floor(activeHeight*0.45);
    CGFloat posX = orientationFrame.size.width/2;
    
    CGPoint newCenter;
    CGFloat rotateAngle;
    
    if (ignoreOrientation) {
        rotateAngle = 0.0;
        newCenter = CGPointMake(posX, posY);
    } else {
        switch (orientation) {
            case UIInterfaceOrientationPortraitUpsideDown:
                rotateAngle = M_PI;
                newCenter = CGPointMake(posX, orientationFrame.size.height-posY);
                break;
            case UIInterfaceOrientationLandscapeLeft:
                rotateAngle = -M_PI/2.0f;
                newCenter = CGPointMake(posY, posX);
                break;
            case UIInterfaceOrientationLandscapeRight:
                rotateAngle = M_PI/2.0f;
                newCenter = CGPointMake(orientationFrame.size.height-posY, posX);
                break;
            default: // as UIInterfaceOrientationPortrait
                rotateAngle = 0.0;
                newCenter = CGPointMake(posX, posY);
                break;
        }
    }
    
    if(notification) {
        [UIView animateWithDuration:animationDuration
                              delay:0
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             [self moveToPoint:newCenter rotateAngle:rotateAngle];
                         } completion:NULL];
    }
    
    else {
        [self moveToPoint:newCenter rotateAngle:rotateAngle];
    }
    
}

- (void)moveToPoint:(CGPoint)newCenter rotateAngle:(CGFloat)angle {
    self.hudView.transform = CGAffineTransformMakeRotation(angle);
    self.hudView.center = CGPointMake(newCenter.x + self.offsetFromCenter.horizontal, newCenter.y + self.offsetFromCenter.vertical);
}

- (void)overlayViewDidReceiveTouchEvent:(id)sender forEvent:(UIEvent *)event {
    [[NSNotificationCenter defaultCenter] postNotificationName:DHImageProgressHudDidReceiveTouchEventNotification object:event];
}

#pragma mark - Master show/dismiss methods

- (void)showWithstatus:(NSString*)string maskType:(DHImageProgressHudType)hudMaskType {
    
    if(!self.overlayView.superview){
        NSEnumerator *frontToBackWindows = [[[UIApplication sharedApplication]windows]reverseObjectEnumerator];
        
        for (UIWindow *window in frontToBackWindows)
            if (window.windowLevel == UIWindowLevelNormal) {
                [window addSubview:self.overlayView];
                break;
            }
    }
    
    if(!self.superview)
        [self.overlayView addSubview:self];
    
    self.fadeOutTimer = nil;
    self.imageView.hidden = YES;
    self.maskType = hudMaskType;
    
    self.stringLabel.text = string;
    [self updatePosition];
    
    self.activityCount++;
    [self.hudView addSubview:self.indefiniteAnimatedView];
    
    if(self.maskType != DHImageProgressHudTypeNone) {
        self.overlayView.userInteractionEnabled = YES;
        self.accessibilityLabel = string;
        self.isAccessibilityElement = YES;
    }
    else {
        self.overlayView.userInteractionEnabled = NO;
        self.hudView.accessibilityLabel = string;
        self.hudView.isAccessibilityElement = YES;
    }
    
    [self.overlayView setHidden:NO];
    self.overlayView.backgroundColor = [UIColor clearColor];
    [self positionHUD:nil];
    
    if(self.alpha != 1) {
        NSDictionary *userInfo = [self notificationUserInfo];
        [[NSNotificationCenter defaultCenter] postNotificationName:DHImageProgressHudWillAppearNotification
                                                            object:nil
                                                          userInfo:userInfo];
        
        [self registerNotifications];
        self.hudView.transform = CGAffineTransformScale(self.hudView.transform, 1.3, 1.3);
        
        if(self.isClear) {
            self.alpha = 1;
            self.hudView.alpha = 0;
        }
        
        [UIView animateWithDuration:0.15
                              delay:0
                            options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.hudView.transform = CGAffineTransformScale(self.hudView.transform, 1/1.3, 1/1.3);
                             
                             if(self.isClear) // handle iOS 7 UIToolbar not answer well to hierarchy opacity change
                                 self.hudView.alpha = 1;
                             else
                                 self.alpha = 1;
                         }
                         completion:^(BOOL finished){
                             [[NSNotificationCenter defaultCenter] postNotificationName:DHImageProgressHudDidAppearNotification
                                                                                 object:nil
                                                                               userInfo:userInfo];
                             UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
                             UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, string);
                         }];
        
        [self setNeedsDisplay];
    }
}

- (UIImage *)image:(UIImage *)image withTintColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, image.scale);
    CGContextRef c = UIGraphicsGetCurrentContext();
    [image drawInRect:rect];
    CGContextSetFillColorWithColor(c, [color CGColor]);
    CGContextSetBlendMode(c, kCGBlendModeSourceAtop);
    CGContextFillRect(c, rect);
    UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return tintedImage;
}

- (void)showImage:(UIImage *)image status:(NSString *)string duration:(NSTimeInterval)duration {
    if(![self.class isVisible])
        [self.class show];
    
    if ([self.imageView respondsToSelector:@selector(setTintColor:)]) {
        self.imageView.tintColor = DHImageProgressHudForegroundColor;
    } else {
        image = [self image:image withTintColor:DHImageProgressHudForegroundColor];
    }
    self.imageView.image = image;
    self.imageView.hidden = NO;
    
    self.stringLabel.text = string;
    [self updatePosition];
    [self.indefiniteAnimatedView removeFromSuperview];
    
    if(self.maskType != DHImageProgressHudTypeNone) {
        self.accessibilityLabel = string;
        self.isAccessibilityElement = YES;
    } else {
        self.hudView.accessibilityLabel = string;
        self.hudView.isAccessibilityElement = YES;
    }
    
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, string);
    
    self.fadeOutTimer = [NSTimer timerWithTimeInterval:duration target:self selector:@selector(dismiss) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:self.fadeOutTimer forMode:NSRunLoopCommonModes];
}

- (void)dismiss {
    NSDictionary *userInfo = [self notificationUserInfo];
    [[NSNotificationCenter defaultCenter] postNotificationName:DHImageProgressHudWillDisappearNotification
                                                        object:nil
                                                      userInfo:userInfo];
    
    self.activityCount = 0;
    [UIView animateWithDuration:0.15
                          delay:0
                        options:UIViewAnimationCurveEaseIn | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.hudView.transform = CGAffineTransformScale(self.hudView.transform, 0.8, 0.8);
                         if(self.isClear) // handle iOS 7 UIToolbar not answer well to hierarchy opacity change
                             self.hudView.alpha = 0;
                         else
                             self.alpha = 0;
                     }
                     completion:^(BOOL finished){
                         if(self.alpha == 0 || self.hudView.alpha == 0) {
                             self.alpha = 0;
                             self.hudView.alpha = 0;
                             
                             [[NSNotificationCenter defaultCenter] removeObserver:self];
                             [_hudView removeFromSuperview];
                             _hudView = nil;
                             
                             [_overlayView removeFromSuperview];
                             _overlayView = nil;
                             
                             [_indefiniteAnimatedView removeFromSuperview];
                             _indefiniteAnimatedView = nil;
                             
                             UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
                             
                             [[NSNotificationCenter defaultCenter] postNotificationName:DHImageProgressHudDidDisappearNotification
                                                                                 object:nil
                                                                               userInfo:userInfo];
                             
                             // Tell the rootViewController to update the StatusBar appearance
                             UIViewController *rootController = [[UIApplication sharedApplication] keyWindow].rootViewController;
                             if ([rootController respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
                                 [rootController setNeedsStatusBarAppearanceUpdate];
                             }
                             // uncomment to make sure UIWindow is gone from app.windows
                             //NSLog(@"%@", [UIApplication sharedApplication].windows);
                             //NSLog(@"keyWindow = %@", [UIApplication sharedApplication].keyWindow);
                         }
                     }];
}


#pragma mark - Ring progress animation

- (UIImageView *)indefiniteAnimatedView {
    if (!_indefiniteAnimatedView)
    {
        NSMutableArray* images = [[NSMutableArray alloc] init];
        UIImage* image = NULL;
        int count = 0;
        do
        {
            NSString* formatString = [NSString stringWithFormat:@"%@_%05d.png", DHImageProgressHudAnimationPrefix, count];
            NSString* imageName = [NSString stringWithFormat:formatString, count];
            image = [UIImage imageNamed:imageName];
            if(image != NULL)
            {
                [images addObject:image];
            }
            count++;
        } while (image != NULL);
        
        if(images.count > 0)
        {
            UIImage* firstImage = [images objectAtIndex:0];
            
            _indefiniteAnimatedView = [[UIImageView alloc] initWithImage:firstImage];
            _indefiniteAnimatedView.contentMode = UIViewContentModeScaleAspectFit;
            _indefiniteAnimatedView.animationImages = images;
            CGPoint center = CGPointMake(CGRectGetWidth(_hudView.frame)/2, CGRectGetHeight(_hudView.frame)/2);
            _indefiniteAnimatedView.center = center;
            //start animation
            _indefiniteAnimatedView.animationDuration = _indefiniteAnimatedView.animationImages.count/ DHImageProgressHudAnimationFPS;
            _indefiniteAnimatedView.animationRepeatCount = 0;
            [_indefiniteAnimatedView startAnimating];
            
        }
    }
    return _indefiniteAnimatedView;
}







#pragma mark - Utilities

+ (BOOL)isVisible {
    return ([self sharedInstance].alpha == 1);
}


#pragma mark - Getters

- (NSTimeInterval)displayDurationForString:(NSString*)string {
    return MIN((float)string.length*0.06 + 0.3, 5.0);
}

- (BOOL)isClear { // used for iOS 7
    return (self.maskType == DHImageProgressHudTypeClear || self.maskType == DHImageProgressHudTypeNone);
}

- (UIControl *)overlayView {
    if(!_overlayView) {
        _overlayView = [[UIControl alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _overlayView.backgroundColor = [UIColor clearColor];
        [_overlayView addTarget:self action:@selector(overlayViewDidReceiveTouchEvent:forEvent:) forControlEvents:UIControlEventTouchDown];
    }
    return _overlayView;
}

- (UIView *)hudView {
    if(!_hudView) {
        _hudView = [[UIView alloc] initWithFrame:CGRectZero];
        _hudView.backgroundColor = DHImageProgressHudBackgroundColor;
        _hudView.layer.cornerRadius = 14;
        _hudView.layer.masksToBounds = YES;
        
        _hudView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin |
                                     UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin);
        
        if ([_hudView respondsToSelector:@selector(addMotionEffect:)]) {
            UIInterpolatingMotionEffect *effectX = [[UIInterpolatingMotionEffect alloc] initWithKeyPath: @"center.x" type: UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
            effectX.minimumRelativeValue = @(-DHImageProgressHudParallaxDepthPoints);
            effectX.maximumRelativeValue = @(DHImageProgressHudParallaxDepthPoints);
            
            UIInterpolatingMotionEffect *effectY = [[UIInterpolatingMotionEffect alloc] initWithKeyPath: @"center.y" type: UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
            effectY.minimumRelativeValue = @(-DHImageProgressHudParallaxDepthPoints);
            effectY.maximumRelativeValue = @(DHImageProgressHudParallaxDepthPoints);
            
            [_hudView addMotionEffect: effectX];
            [_hudView addMotionEffect: effectY];
        }
        
        [self addSubview:_hudView];
    }
    return _hudView;
}

- (UILabel *)stringLabel {
    if (_stringLabel == nil) {
        _stringLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _stringLabel.backgroundColor = [UIColor clearColor];
        _stringLabel.adjustsFontSizeToFitWidth = YES;
        _stringLabel.textAlignment = NSTextAlignmentCenter;
        _stringLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        _stringLabel.textColor = DHImageProgressHudForegroundColor;
        _stringLabel.font = DHImageProgressHudFont;
        _stringLabel.numberOfLines = 0;
    }
    
    if(!_stringLabel.superview)
        [self.hudView addSubview:_stringLabel];
    
    return _stringLabel;
}

- (UIImageView *)imageView {
    if (_imageView == nil)
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 28, 28)];
    
    if(!_imageView.superview)
        [self.hudView addSubview:_imageView];
    
    return _imageView;
}


- (CGFloat)visibleKeyboardHeight {
    
    UIWindow *keyboardWindow = nil;
    for (UIWindow *testWindow in [[UIApplication sharedApplication] windows]) {
        if(![[testWindow class] isEqual:[UIWindow class]]) {
            keyboardWindow = testWindow;
            break;
        }
    }
    
    for (__strong UIView *possibleKeyboard in [keyboardWindow subviews]) {
        if([possibleKeyboard isKindOfClass:NSClassFromString(@"UIPeripheralHostView")] || [possibleKeyboard isKindOfClass:NSClassFromString(@"UIKeyboard")])
            return possibleKeyboard.bounds.size.height;
    }
    
    return 0;
}

@end

