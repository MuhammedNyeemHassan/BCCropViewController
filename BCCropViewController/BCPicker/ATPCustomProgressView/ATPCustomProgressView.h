//
//  ATPCustomProgressView.h
//  AddTextToPhoto
//
//  Created by Arsil Ajim on 4/1/21.
//  Copyright © 2021 Brain Craft Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
@import Photos;

typedef enum : NSUInteger {
    StickerDownload,
    PhotoPickerDownload,
} DownloadType;

typedef void(^ATPCustomProgressCancelBlock)(BOOL cancelled);
typedef ATPCustomProgressCancelBlock ATPCustomProgressCancelBlock;

@interface ATPCustomProgressView : UIView
@property (weak, nonatomic) IBOutlet UIView *progressHolderView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressIndicatorView;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *progressHolderYCenterConstraint;
@property (nonatomic) ATPCustomProgressCancelBlock cancelBlock;

+ (void)showLoadingViewWithText:(NSString*)text withProgress:(CGFloat)progress withType:(DownloadType)progressType;
+ (void)showLoadingViewWithText:(NSString*)text withProgress:(CGFloat)progress withCancelationBlock:(ATPCustomProgressCancelBlock)cancelBlock;
+ (void) removeLoadingView;
+(void) progressWithGradientIntialize:(UIProgressView *)slider;
- (IBAction)cancelDownload:(id)sender;
@property (nonatomic) DownloadType progressViewType;

@end
