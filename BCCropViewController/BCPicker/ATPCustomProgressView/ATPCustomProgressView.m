//
//  ATPCustomProgressView.m
//  AddTextToPhoto
//
//  Created by Arsil Ajim on 4/1/21.
//  Copyright © 2021 Brain Craft Ltd. All rights reserved.
//

#import "ATPCustomProgressView.h"
//#import "APIManager.h"

//76D6F8
#define SLIDER_GRADIENT_START_COLOR [UIColor colorWithRed:118.0/255.0 green:214.0/255.0 blue:248.0/255.0 alpha:1.0]
//#00BAFF
#define SLIDER_GRADIENT_END_COLOR [UIColor colorWithRed:0.0/255.0 green:186.0/255.0 blue:255.0/255.0 alpha:1.0]

@implementation ATPCustomProgressView

+ (ATPCustomProgressView *)sharedLoadingView {
    static dispatch_once_t once;
    
    static ATPCustomProgressView *sharedView;
    dispatch_once(&once, ^{
        sharedView = [[[NSBundle mainBundle] loadNibNamed:@"ATPCustomProgressView" owner:nil options:nil] objectAtIndex:0];
        [sharedView registerNotifications];
        
    });
    return sharedView;
}

+ (ATPCustomProgressView *)loaderWithText:(NSString*)text withProgress:(CGFloat)progress {
    [self sharedLoadingView].frame = UIScreen.mainScreen.bounds;
    [self sharedLoadingView].messageLabel.text = text;
    [((UIButton *)[[self sharedLoadingView] viewWithTag:299]).titleLabel setFont:[UIFont fontWithName:@"BeVietnam-Medium" size:14.0f]];
    [self progressWithGradientIntialize:[self sharedLoadingView].progressIndicatorView];
    [[self sharedLoadingView].progressIndicatorView setProgress:progress animated:YES];
    
    return [self sharedLoadingView];
}

+ (void)showLoadingViewWithText:(NSString*)text withProgress:(CGFloat)progress withType:(DownloadType)progressType {
    [[[self sharedLoadingView] frontWindow] addSubview:[self loaderWithText:text withProgress:progress]];
    [[self sharedLoadingView] positionHUD:nil];
    [self sharedLoadingView].progressViewType = progressType;
}

+ (void)showLoadingViewWithText:(NSString*)text withProgress:(CGFloat)progress withCancelationBlock:(ATPCustomProgressCancelBlock)cancelBlock
{
    if(cancelBlock)
        [[self sharedLoadingView] setCancelBlock:cancelBlock];
    [self showLoadingViewWithText:text withProgress:progress withType:[self sharedLoadingView].progressViewType];
}

#pragma mark - Gradient ProgressView
+(void) progressWithGradientIntialize:(UIProgressView *)slider {
    BOOL gradientAdded = NO;
    CAGradientLayer *sliderLayer;
    for (CALayer *layer in slider.layer.sublayers) {
        if ([layer isKindOfClass:[CAGradientLayer class]]) {
            gradientAdded = YES;
            sliderLayer = (CAGradientLayer *)layer;
            break;
        }
    }
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    if (gradientAdded == NO) {
        [self gradientSlider:slider];
        for (CALayer *layer in slider.layer.sublayers) {
            if ([layer isKindOfClass:[CAGradientLayer class]]) {
                sliderLayer = (CAGradientLayer *)layer;
                break;
            }
        }
    }
    sliderLayer.frame = CGRectMake(0, 0, slider.frame.size.width * slider.progress, 3);
    NSLog(@"sliderLayer.frame: %f slider.progress: %f",sliderLayer.frame.size.width, slider.progress);
    [CATransaction commit];
}

+(void)gradientSlider:(UIProgressView *)slider {
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = CGRectMake(0, 0, slider.frame.size.width * slider.progress, slider.frame.size.height);
    gradient.colors = @[(id)SLIDER_GRADIENT_START_COLOR.CGColor, (id)SLIDER_GRADIENT_END_COLOR.CGColor];
    gradient.startPoint = CGPointMake(0, 1);
    gradient.endPoint = CGPointMake(1, 1);
    gradient.cornerRadius = 1.5;
    [slider.layer addSublayer:gradient];
}

+ (void)removeLoadingView {
//    [self showLoadingViewWithText:[self sharedLoadingView].messageLabel.text withProgress:0 withType:[self sharedLoadingView].progressViewType];
    CAGradientLayer *sliderLayer;
    for (CALayer *layer in [self sharedLoadingView].progressIndicatorView.layer.sublayers) {
        if ([layer isKindOfClass:[CAGradientLayer class]]) {
            sliderLayer = (CAGradientLayer *)layer;
            break;
        }
    }
    sliderLayer.frame = CGRectZero;
    [sliderLayer removeFromSuperlayer];
    [[self sharedLoadingView] removeFromSuperview];
}

#pragma mark - Helper
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
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(positionHUD:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}
- (CGFloat)visibleKeyboardHeight {
    UIWindow *keyboardWindow = nil;
    for (UIWindow *testWindow in UIApplication.sharedApplication.windows) {
        if(![testWindow.class isEqual:UIWindow.class]) {
            keyboardWindow = testWindow;
            break;
        }
    }
    
    for (__strong UIView *possibleKeyboard in keyboardWindow.subviews) {
        NSString *viewName = NSStringFromClass(possibleKeyboard.class);
        if([viewName hasPrefix:@"UI"]){
            if([viewName hasSuffix:@"PeripheralHostView"] || [viewName hasSuffix:@"Keyboard"]){
                return CGRectGetHeight(possibleKeyboard.bounds);
            } else if ([viewName hasSuffix:@"InputSetContainerView"]){
                for (__strong UIView *possibleKeyboardSubview in possibleKeyboard.subviews) {
                    viewName = NSStringFromClass(possibleKeyboardSubview.class);
                    if([viewName hasPrefix:@"UI"] && [viewName hasSuffix:@"InputSetHostView"]) {
                        CGRect convertedRect = [possibleKeyboard convertRect:possibleKeyboardSubview.frame toView:self];
                        CGRect intersectedRect = CGRectIntersection(convertedRect,self.bounds);
                        if (!CGRectIsNull(intersectedRect)) {
                            return CGRectGetHeight(intersectedRect);
                        }
                    }
                }
            }
        }
    }
    return 0;
}

- (UIWindow *)frontWindow {
    NSEnumerator *frontToBackWindows = [UIApplication.sharedApplication.windows reverseObjectEnumerator];
    for (UIWindow *window in frontToBackWindows) {
        BOOL windowOnMainScreen = window.screen == UIScreen.mainScreen;
        BOOL windowIsVisible = !window.hidden && window.alpha > 0;
        BOOL windowLevelSupported = (window.windowLevel >= UIWindowLevelNormal && window.windowLevel <= UIWindowLevelNormal);
        BOOL windowKeyWindow = window.isKeyWindow;
        
        if(windowOnMainScreen && windowIsVisible && windowLevelSupported && windowKeyWindow) {
            return window;
        }
    }
    return nil;
}

- (void)positionHUD:(NSNotification*)notification {
    CGFloat keyboardHeight = 0.0f;
    double animationDuration = 0.0;
    
    self.frame = [[[UIApplication sharedApplication] delegate] window].bounds;
    UIInterfaceOrientation orientation = UIApplication.sharedApplication.statusBarOrientation;
    
    // Get keyboardHeight in regard to current state
    if(notification) {
        NSDictionary* keyboardInfo = [notification userInfo];
        CGRect keyboardFrame = [keyboardInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
        animationDuration = [keyboardInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        
        if(notification.name == UIKeyboardWillShowNotification || notification.name == UIKeyboardDidShowNotification) {
            keyboardHeight = CGRectGetWidth(keyboardFrame);
            
            if(UIInterfaceOrientationIsPortrait(orientation)) {
                keyboardHeight = CGRectGetHeight(keyboardFrame);
            }
        }
    } else {
        keyboardHeight = [self visibleKeyboardHeight];
    }
    
    // Get the currently active frame of the display (depends on orientation)
    CGRect orientationFrame = self.bounds;
    
    CGRect statusBarFrame = UIApplication.sharedApplication.statusBarFrame;
    
    // Calculate available height for display
    CGFloat activeHeight = CGRectGetHeight(orientationFrame);
    if(keyboardHeight > 0) {
        activeHeight += CGRectGetHeight(statusBarFrame) * 2;
    }
    activeHeight -= keyboardHeight;
    
    CGFloat posX = CGRectGetMidX(orientationFrame);
    CGFloat posY = activeHeight / 2.0;//floorf(activeHeight*0.45f);
    
    CGFloat rotateAngle = 0.0;
    CGPoint newCenter = CGPointMake(posX, posY);
    
    if(notification) {
        // Animate update if notification was present
        [UIView animateWithDuration:animationDuration
                              delay:0
                            options:(UIViewAnimationOptions) (UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState)
                         animations:^{
            [self moveToPoint:newCenter rotateAngle:rotateAngle];
            [self.progressHolderView setNeedsDisplay];
        } completion:nil];
    } else {
        [self moveToPoint:newCenter rotateAngle:rotateAngle];
        [self.progressHolderView setNeedsDisplay];
    }
}

- (void)moveToPoint:(CGPoint)newCenter rotateAngle:(CGFloat)angle {
    self.progressHolderView.transform = CGAffineTransformMakeRotation(angle);
    _progressHolderYCenterConstraint.constant = (self.center.y - newCenter.y) * -1;
}
- (IBAction)cancelDownload:(id)sender {
    
//    if (self.progressViewType == StickerDownload) {
////        [APIManager.sharedManager cancelCurrentDownload];
//        return;
//    }
    
    if(self.cancelBlock)
    {
        self.cancelBlock(YES);
        [self setCancelBlock:nil];
    }
    
    [ATPCustomProgressView removeLoadingView];
}

@end
