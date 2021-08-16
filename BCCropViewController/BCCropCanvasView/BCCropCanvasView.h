//
//  BCCropCanvasView.h
//  BCCropViewController
//
//  Created by Somoy Das Gupta on 3/8/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BCCropIntersectionInfo: NSObject

@property (nonatomic) BOOL isIntersected;
@property (nonatomic) CGPoint intersectionPoint;
@property (nonatomic) CGPoint intersectedPoint;

@end

@interface BCCropCanvasView : UIView

@property (strong, nonatomic) UIImage *inputImage;

- (void)rotateImageLayer:(CGFloat)angle;
- (void)skewImageLayerHorizontally:(CGFloat)skewAngle shouldReset:(BOOL)reset;
- (void)skewImageLayerVertically:(CGFloat)skewAngle shouldReset:(BOOL)reset;

-(void)flipImageHorizontal;
-(void)flipImageVertical;
- (IBAction)saveToGalleryTapped;
-(UIImage *)saveModelAndApply;


@end

NS_ASSUME_NONNULL_END
