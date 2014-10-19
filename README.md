# DHImageProgressHud

DHImageProgressHud is a easy to use Hud built on the same foundation as [SVProgressHUD](https://github.com/TransitApp/SVProgressHUD).
Instead of displaying the standard spinner, DHImageProgressHud enable developers to simply
plug a set of animation frames and loop through that as the loading view.

<!--![SVProgressHUD](http://f.cl.ly/items/2G1F1Z0M0k0h2U3V1p39/SVProgressHUD.gif)-->

## Installation

### Manual Installation
* Sorry cocoapods not available yet. I'm still in the middle of getting things together.
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
## Setting your own Animation Images

In order to load your images into DHImageProgressHud :

All Image files must be named in sequential order and must be 4 digits (padded with 0's if necessary).

 example :coffee_0000.png, this represents the first frame of our animation
```objective-c
+ (void)setAnimationImagePrefix:(NSString *)imagePrefix numOfFrames:(NSInteger)frames;

[DHImageProgressHud setAnimationImagePrefix:@"coffee" numOfFrames:3];
```


<!--Each notification passes a `userInfo` dictionary holding the HUD's status string (if any), retrievable via `SVProgressHUDStatusUserInfoKey`.-->

<!--`DHImageProgressHud` also posts `SVProgressHUDDidReceiveTouchEventNotification` when users touch on the screen. For this notification `userInfo` is not passed but the object parameter contains the `UIEvent` that related to the touch.-->

## Credits
DHImageProgressHud was inspired by and built on top of Sam Vermette's [SVProgressHUD](https://github.com/TransitApp/SVProgressHUD)
