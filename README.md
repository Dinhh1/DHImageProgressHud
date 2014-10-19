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
## Setting your own Animation Images

In order to load your images into DHImageProgressHud :

All Image files must be named in sequential order and must be 5 digits (padded with 0's if necessary).

 example :coffee_00000.png, this represents the first frame of our animation
```objective-c
+ (void)setAnimationImagePrefix:(NSString *)imagePrefix numOfFrames:(NSInteger)frames;

[DHImageProgressHud setAnimationImagePrefix:@"coffee" numOfFrames:3];
```


<!--Each notification passes a `userInfo` dictionary holding the HUD's status string (if any), retrievable via `SVProgressHUDStatusUserInfoKey`.-->

<!--`DHImageProgressHud` also posts `SVProgressHUDDidReceiveTouchEventNotification` when users touch on the screen. For this notification `userInfo` is not passed but the object parameter contains the `UIEvent` that related to the touch.-->

## Credits
DHImageProgressHud was inspired by Sam Vermette's [SVProgressHUD](https://github.com/TransitApp/SVProgressHUD)
