//
//  BCCropViewController.h
//  BCPicker
//
//  Created by Somoy Das Gupta on 25/7/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum{
    HorizontalSkew = 0,
    VerticalSkew,
    Skew360,
} SkewType;


@interface BCCropViewController : UIViewController

@property (strong, nonatomic) UIImage *selectedImage;

@end

NS_ASSUME_NONNULL_END
