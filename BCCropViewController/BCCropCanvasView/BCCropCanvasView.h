//
//  BCCropCanvasView.h
//  BCCropViewController
//
//  Created by Somoy Das Gupta on 3/8/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BCCropCanvasView : UIView

@property (strong, nonatomic) UIImage *inputImage;

- (void)rotateImageLayer:(CGFloat)angle;
- (void)skewImageLayerHorizontally:(CGFloat)skewAngle;
- (void)skewImageLayerVertically:(CGFloat)skewAngle;
@end

NS_ASSUME_NONNULL_END
