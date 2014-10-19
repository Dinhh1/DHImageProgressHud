# DHImageProgressHud

DHImageProgressHud is a clean and easy-to-use HUD meant to display the progress of an ongoing task.

<!--![SVProgressHUD](http://f.cl.ly/items/2G1F1Z0M0k0h2U3V1p39/SVProgressHUD.gif)-->

## Installation

### Manually

* Drag the `DHImageProgressHud/DHImageProgressHud` folder into your project.
* Add the **QuartzCore** framework to your project.

## Usage


Example Use Case 

```objective-c
[DHImageProgressHud show];
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    // time-consuming task
    dispatch_async(dispatch_get_main_queue(), ^{
        [DHImageProgressHud dismiss];
    });
});
```

### Showing the HUD

You can show the status of indeterminate tasks using one of the following:

<!--```objective-c-->
<!--+ (void)show;-->
<!--+ (void)showWithMaskType:(SVProgressHUDMaskType)maskType;-->
<!--+ (void)showWithStatus:(NSString*)string;-->
<!--+ (void)showWithStatus:(NSString*)string maskType:(SVProgressHUDMaskType)maskType;-->
<!--```-->

If you'd like the HUD to reflect the progress of a task, use one of these:

<!--```objective-c-->
<!--+ (void)showProgress:(CGFloat)progress;-->
<!--+ (void)showProgress:(CGFloat)progress status:(NSString*)status;-->
<!--+ (void)showProgress:(CGFloat)progress status:(NSString*)status maskType:(SVProgressHUDMaskType)maskType;-->
<!--```-->

### Dismissing the HUD

It can be dismissed right away using:

<!--```objective-c-->
<!--+ (void)dismiss;-->
<!--```-->

If you'd like to stack HUDs, you can balance out every show call using:

<!--```objective-c-->
<!--+ (void)popActivity;-->
<!--```-->

The HUD will get dismissed once the `popActivity` calls will match the number of show calls.  

Or show a confirmation glyph before before getting dismissed 1 second later using:

<!--```objective-c-->
<!--+ (void)showSuccessWithStatus:(NSString*)string;-->
<!--+ (void)showErrorWithStatus:(NSString *)string;-->
<!--+ (void)showImage:(UIImage*)image status:(NSString*)string; // use 28x28 pngs-->
<!--```-->

## Customization

SVProgressHUD can be customized via the following methods:

<!--```objective-c-->
<!--+ (void)setBackgroundColor:(UIColor*)color; // default is [UIColor whiteColor]-->
<!--+ (void)setForegroundColor:(UIColor*)color; // default is [UIColor blackColor]-->
<!--+ (void)setRingThickness:(CGFloat)width; // default is 4 pt-->
<!--+ (void)setFont:(UIFont*)font; // default is [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]-->
<!--+ (void)setSuccessImage:(UIImage*)image; // default is bundled success image from Glyphish-->
<!--+ (void)setErrorImage:(UIImage*)image; // default is bundled error image from Glyphish-->
<!--```-->

## Notifications

<!--`SVProgressHUD` posts four notifications via `NSNotificationCenter` in response to being shown/dismissed:-->
<!--* `SVProgressHUDWillAppearNotification` when the show animation starts-->
<!--* `SVProgressHUDDidAppearNotification` when the show animation completes-->
<!--* `SVProgressHUDWillDisappearNotification` when the dismiss animation starts-->
<!--* `SVProgressHUDDidDisappearNotification` when the dismiss animation completes-->

<!--Each notification passes a `userInfo` dictionary holding the HUD's status string (if any), retrievable via `SVProgressHUDStatusUserInfoKey`.-->

<!--`DHImageProgressHud` also posts `SVProgressHUDDidReceiveTouchEventNotification` when users touch on the screen. For this notification `userInfo` is not passed but the object parameter contains the `UIEvent` that related to the touch.-->

## Credits
DHImageProgressHud was inspired by Sam Vermette's [SVProgressHUD](https://github.com/TransitApp/SVProgressHUD)
