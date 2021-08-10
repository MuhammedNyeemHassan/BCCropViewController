//
//  BCCropCanvasView.m
//  BCCropViewController
//
//  Created by Somoy Das Gupta on 3/8/21.
//

#import "BCCropCanvasView.h"
#import "UIImage+Utility.h"
#import "BCCropLayer.h"
#import <AVFoundation/AVFoundation.h>

static const CGFloat kMinimumCropAreaInset = 15.0;
static const CGFloat kMinimumCropAreaSide = 54.0;

static CGFloat distanceBetweenPoints(CGPoint point0, CGPoint point1)
{
    return sqrt(pow(point1.x - point0.x, 2) + pow(point1.y - point0.y, 2));
}

CG_INLINE CGFloat CGAffineTransformGetAngle(CGAffineTransform t) {
    return atan2(t.b, t.a);
}

@interface BCCropCanvasView () {
    
    CGPoint initialLocation;
    
    CGRect initialCropLayerFrame;
    BOOL cropCornerSelected;
    BCCropCornerType selectedCropCorner;
    
    CGRect initialImageLayerFrame;
    CGPoint imageLayerCurrentAnchorPosition;
    
    CGFloat zoomScale;
    CGFloat rotationAngle;
    
    CGFloat skewAngleH;
    CGFloat skewAngleV;
    
    CGPoint imageTopRightPoint, imageTopLeftPoint, imageBottomLeftPoint,imageBottomRightPoint;
    CAShapeLayer *shapeLayer;
}
@property (strong, nonatomic) CIContext *context;

@property (strong, nonatomic) CALayer *imageLayerContainerLayer;
@property (strong, nonatomic) CALayer *imageLayer;
@property (strong, nonatomic) BCCropLayer *cropLayer;

@property (strong, nonatomic) UIPanGestureRecognizer *pan;
@property (strong, nonatomic) UIPinchGestureRecognizer *pinch;

@property CGRect fitImageFrame;
@end

@implementation BCCropCanvasView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    
    zoomScale = 1;
    self.backgroundColor = UIColor.darkGrayColor;
    self.clipsToBounds = YES;
    self.context = [CIContext context];
    [self prepareImageLayerContainerLayer];
    [self prepareImageLayer];
    [self prepareShapeLayer];
    [self prepareCropLayer];
    [self prepareGestureRecognizers];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    _imageLayerContainerLayer.frame = self.layer.bounds;
    [CATransaction commit];
    
    if (CGRectIsEmpty(_fitImageFrame) && _inputImage) {
        
        _fitImageFrame = CGRectIntegral(AVMakeRectWithAspectRatioInsideRect(_inputImage.size, CGRectMake(kMinimumCropAreaInset, kMinimumCropAreaInset, (self.bounds.size.width - (kMinimumCropAreaInset * 2.0)), (self.bounds.size.height - (kMinimumCropAreaInset * 2.0)))));
        [self resetImageLayerFrame];
        [self resetCropLayerFrame];
    }
}

//MARK:- Property setters
- (void)setInputImage:(UIImage *)inputImage {
    _inputImage = inputImage;
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    _imageLayer.contents = (__bridge id)[_inputImage createCGImageRef];
    [CATransaction commit];
    [self setImageCornerPoints];
}

- (void)setImageCornerPoints {
    
    imageTopLeftPoint = CGPointMake(0, _inputImage.size.height);
    imageTopRightPoint = CGPointMake(_inputImage.size.width, _inputImage.size.height);
    imageBottomLeftPoint = CGPointMake(0, 0);
    imageBottomRightPoint = CGPointMake(_inputImage.size.width, 0);
}

//MARK:- Prepare Layers
- (void)prepareImageLayerContainerLayer {
    
    _imageLayerContainerLayer = [[CALayer alloc] init];
    _imageLayerContainerLayer.contentsGravity = kCAGravityResize;
    _imageLayerContainerLayer.frame = self.layer.bounds;
    
    [self.layer addSublayer:_imageLayerContainerLayer];
}

- (void)prepareImageLayer {
    
    _imageLayer = [[CALayer alloc] init];
    _imageLayer.contentsGravity = kCAGravityResize;
    _imageLayer.backgroundColor = UIColor.blackColor.CGColor;
    _imageLayer.shouldRasterize = YES;
    _imageLayer.rasterizationScale = UIScreen.mainScreen.scale;
    [_imageLayerContainerLayer addSublayer:_imageLayer];
}

- (void)prepareShapeLayer {
    
    shapeLayer = [CAShapeLayer layer];
    shapeLayer.shouldRasterize = YES;
    shapeLayer.rasterizationScale = UIScreen.mainScreen.scale;
    shapeLayer.geometryFlipped = YES;
    [_imageLayerContainerLayer addSublayer:shapeLayer];
    
    shapeLayer.fillColor = [UIColor.blueColor colorWithAlphaComponent:0.4].CGColor;
    shapeLayer.backgroundColor = [UIColor.greenColor colorWithAlphaComponent:0.4].CGColor;
}

- (void)resetImageLayerFrame {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    _imageLayer.frame = _fitImageFrame;
    shapeLayer.bounds = _imageLayer.bounds;
    shapeLayer.position = _imageLayer.position;
    [CATransaction commit];
        
    [self resetShapeLayerPath];
}

- (void)prepareCropLayer {
    
    _cropLayer = [[BCCropLayer alloc] initWithFrame:self.bounds];
    [self.layer addSublayer:_cropLayer];
}

- (void)resetCropLayerFrame {
    _cropLayer.frame = _fitImageFrame;
}

- (void)resetShapeLayerPath {
    
    CGRect fittedImageRect = AVMakeRectWithAspectRatioInsideRect(_inputImage.size, self.imageLayer.bounds);
    CGFloat scaleX = fittedImageRect.size.width / _inputImage.size.width;
    CGFloat scaleY = fittedImageRect.size.height / _inputImage.size.height;
    CGAffineTransform scaleTransform = CGAffineTransformMakeScale(scaleX, scaleY);
    
    CGPoint bl = CGPointApplyAffineTransform(imageBottomLeftPoint, scaleTransform);
    CGPoint tl = CGPointApplyAffineTransform(imageTopLeftPoint, scaleTransform);
    CGPoint tr = CGPointApplyAffineTransform(imageTopRightPoint, scaleTransform);
    CGPoint br = CGPointApplyAffineTransform(imageBottomRightPoint, scaleTransform);
    
    UIBezierPath *bezierPath = [[UIBezierPath alloc] init];
    [bezierPath moveToPoint:bl];
    [bezierPath addLineToPoint:tl];
    [bezierPath addLineToPoint:tr];
    [bezierPath addLineToPoint:br];
    [bezierPath closePath];
    shapeLayer.path = bezierPath.CGPath;

    CGPoint poinstArray[] = {bl, tl, tr, br};
    CGRect smallestRect = CGRectSmallestWithCGPoints(poinstArray, 4);
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    shapeLayer.bounds = smallestRect;
    shapeLayer.position = _imageLayer.position;
    _imageLayer.bounds = shapeLayer.bounds;
    [CATransaction commit];
}

//MARK:- Prepare Gestures
- (void)prepareGestureRecognizers {
    
    _pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureApplied:)];
    [self addGestureRecognizer:_pan];
    
    _pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGestureApplied:)];
    [self addGestureRecognizer:_pinch];
}

//MARK:- Gesture Actions
- (void)panGestureApplied:(UIPanGestureRecognizer *)sender {
    
    if(sender.state == UIGestureRecognizerStateBegan) {
        initialLocation = [sender locationInView:sender.view];
        initialCropLayerFrame = _cropLayer.frame;
        cropCornerSelected = [_cropLayer didTouchAnyCorner:initialLocation];
        selectedCropCorner = [_cropLayer touchedCorner:initialLocation];
        
        initialImageLayerFrame = _imageLayer.frame;
    }
    
    if (sender.state == UIGestureRecognizerStateBegan ||
        sender.state == UIGestureRecognizerStateChanged) {
        
        if (cropCornerSelected) {
            CGPoint location = [sender locationInView:sender.view];
            
            CGFloat xPannedDistance = location.x - initialLocation.x;
            CGFloat yPannedDistance = location.y - initialLocation.y;
            
            CGFloat newCropLayerWidth = initialCropLayerFrame.size.width;
            CGFloat newCropLayerHeight = initialCropLayerFrame.size.height;
            
            CGPoint newCropLayerOrigin = initialCropLayerFrame.origin;
            
            switch (selectedCropCorner) {
                    
                case BCCropCornerTypeUpperLeft: {
                    newCropLayerWidth = newCropLayerWidth - xPannedDistance;
                    newCropLayerHeight = newCropLayerHeight - yPannedDistance;
                    
                    if (newCropLayerWidth < kMinimumCropAreaSide) {
                        newCropLayerWidth = kMinimumCropAreaSide;
                        xPannedDistance = initialCropLayerFrame.size.width - kMinimumCropAreaSide;
                    }
                    if (newCropLayerHeight < kMinimumCropAreaSide) {
                        newCropLayerHeight = kMinimumCropAreaSide;
                        yPannedDistance = initialCropLayerFrame.size.height - kMinimumCropAreaSide;
                    }
                    
                    newCropLayerOrigin.x = newCropLayerOrigin.x + xPannedDistance;
                    newCropLayerOrigin.y = newCropLayerOrigin.y + yPannedDistance;
                    break;
                }
                    
                case BCCropCornerTypeUpperRight: {
                    newCropLayerWidth = newCropLayerWidth + xPannedDistance;
                    newCropLayerHeight = newCropLayerHeight - yPannedDistance;
                    
                    if (newCropLayerWidth < kMinimumCropAreaSide) {
                        newCropLayerWidth = kMinimumCropAreaSide;
                    }
                    if (newCropLayerHeight < kMinimumCropAreaSide) {
                        newCropLayerHeight = kMinimumCropAreaSide;
                        yPannedDistance = initialCropLayerFrame.size.height - kMinimumCropAreaSide;
                    }
                    
                    newCropLayerOrigin.y = newCropLayerOrigin.y + yPannedDistance;
                    
                    break;
                }
                    
                case BCCropCornerTypeLowerLeft: {
                    newCropLayerWidth = newCropLayerWidth - xPannedDistance;
                    newCropLayerHeight = newCropLayerHeight + yPannedDistance;
                    
                    if (newCropLayerWidth < kMinimumCropAreaSide) {
                        newCropLayerWidth = kMinimumCropAreaSide;
                        xPannedDistance = initialCropLayerFrame.size.width - kMinimumCropAreaSide;
                    }
                    if (newCropLayerHeight < kMinimumCropAreaSide) {
                        newCropLayerHeight = kMinimumCropAreaSide;
                    }
                    
                    newCropLayerOrigin.x = newCropLayerOrigin.x + xPannedDistance;
                    break;
                }
            
                case BCCropCornerTypeLowerRight: {
                    
                    newCropLayerWidth = newCropLayerWidth + xPannedDistance;
                    newCropLayerHeight = newCropLayerHeight + yPannedDistance;
                    
                    if (newCropLayerWidth < kMinimumCropAreaSide) {
                        newCropLayerWidth = kMinimumCropAreaSide;
                    }
                    if (newCropLayerHeight < kMinimumCropAreaSide) {
                        newCropLayerHeight = kMinimumCropAreaSide;
                    }
                    
                    break;
                }
                    
                default: {
                    break;
                }
            }
            
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            _cropLayer.frame = CGRectMake(newCropLayerOrigin.x, newCropLayerOrigin.y, newCropLayerWidth, newCropLayerHeight);
            [CATransaction commit];
        }
        else {
            
            CGPoint translation = [sender translationInView:self];
            CGPoint velocity = [sender velocityInView:self];
            
            if (CGPointEqualToPoint(translation, CGPointZero)) {
                //No Calculations when zero movement
                return;
            }
            
            CGPoint newPosition = _imageLayer.position;
            
            if (rotationAngle == 0 && skewAngleV == 0 && skewAngleH == 0) {
                if ([self canImageLayerMoveHorizontally:translation.x]) {
                    newPosition.x = newPosition.x + translation.x;
                }
                else { //For removing lagging in speedy pan
                    if (velocity.x != 0) {
                        if(velocity.x > 0) { //Moving right
                            newPosition.x = _cropLayer.position.x - _cropLayer.frame.size.width + _imageLayer.frame.size.width;
                        }
                        else //Moving left
                        {
                            newPosition.x = _cropLayer.position.x + _cropLayer.frame.size.width - _imageLayer.frame.size.width;
                        }
                    }
                }
                
                if ([self canImageLayerMoveVertically:translation.y]) {
                    newPosition.y = newPosition.y + translation.y;
                }
                else { //For removing lagging in speedy pan
                    if (velocity.y != 0) {
                        if(velocity.y > 0) { //Moving down
                            newPosition.y = _cropLayer.position.y + _cropLayer.frame.size.height - _imageLayer.frame.size.height;;
                        }
                        else //Moving up
                        {
                            newPosition.y = _cropLayer.position.y + _cropLayer.frame.size.height - _imageLayer.frame.size.height;
                        }
                    }
                }
                
            }
            else {
                
                newPosition.x = newPosition.x + translation.x;
                newPosition.y = newPosition.y + translation.y;
            }
            
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            _imageLayer.position = newPosition;
            shapeLayer.position = newPosition;
            [CATransaction commit];
        }
        
        [sender setTranslation:CGPointMake(0, 0) inView:self];
    }
    
    if (sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateCancelled) {
        
        if(cropCornerSelected) {
            [self resizeLayersAfterCropLayerCornerDrag];
        }
        cropCornerSelected = NO;
    }
}

- (void)pinchGestureApplied:(UIPinchGestureRecognizer *)sender {
    
    CGPoint location = [sender locationInView:sender.view];
    if (![_cropLayer hitTest:location]) {
        return;
    }
    
    if(sender.state == UIGestureRecognizerStateBegan) {
        initialLocation = [sender locationInView:sender.view];
        initialImageLayerFrame = _imageLayer.bounds;
        
        //Zoom in/out with respect to current crop center / imagelayer anchor
        imageLayerCurrentAnchorPosition = [self getCurrentImageLayerAnchorPoint];
    }
    
    if (sender.state == UIGestureRecognizerStateBegan || sender.state == UIGestureRecognizerStateChanged) {
        
        CGRect scaledFrame = [self calculateImageLayerScaledFrame:initialImageLayerFrame scale:sender.scale anchorPoint:imageLayerCurrentAnchorPosition];
        
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        _imageLayer.bounds = scaledFrame;
        shapeLayer.bounds = scaledFrame;
        [self resetShapeLayerPath];
        [CATransaction commit];
        
        zoomScale = sender.scale;
    }
}

- (CGPoint)getCurrentImageLayerAnchorPoint {
    
    CGPoint cropLayerCenter = CGPointMake(CGRectGetMidX(_cropLayer.frame), CGRectGetMidY(_cropLayer.frame));
    CGPoint imageLayerCurrentZoomCenter = [_imageLayerContainerLayer convertPoint:cropLayerCenter toLayer:_imageLayer];
    
    return CGPointMake(imageLayerCurrentZoomCenter.x / _imageLayer.frame.size.width, imageLayerCurrentZoomCenter.y / _imageLayer.frame.size.height);
}

- (CGRect)calculateImageLayerScaledFrame:(CGRect)frame scale:(CGFloat)scale anchorPoint:(CGPoint)anchor {
    
    CGFloat newWidth = frame.size.width;
    CGFloat newHeight = frame.size.height;
    
    //Check which side is bigger
    if (_fitImageFrame.size.width <= _fitImageFrame.size.height) {
        newWidth = newWidth * scale;
        newHeight = newWidth * frame.size.height / frame.size.width;
    } else {
        newHeight = newHeight * scale;
        newWidth = newHeight * frame.size.width / frame.size.height;
    }
    
    //Check minimum imageLayer frame size
    if (newWidth < _cropLayer.bounds.size.width || newHeight < _cropLayer.bounds.size.height) {
        
        if (_fitImageFrame.size.width <= _fitImageFrame.size.height) {
            newWidth = _cropLayer.bounds.size.width;
            newHeight = newWidth * _fitImageFrame.size.height / _fitImageFrame.size.width;
        } else {
            newHeight = _cropLayer.bounds.size.height;
            newWidth = newHeight * _fitImageFrame.size.width / _fitImageFrame.size.height;
        }
    }
    
    //Calculate origin change
//    CGFloat translationX = (frame.size.width - newWidth) * anchor.x;
//    CGFloat translationY = (frame.size.height - newHeight) * anchor.y;
//
//    CGPoint newOrigin = CGPointMake(frame.origin.x + translationX, frame.origin.y + translationY);
//
//    //Left-Right bound check
//    if (!(newOrigin.x < _cropLayer.frame.origin.x)) {
//        newOrigin.x = _cropLayer.frame.origin.x;
//    }
//    else if (!((newOrigin.x + newWidth) > (_cropLayer.frame.origin.x + _cropLayer.frame.size.width))) {
//        newOrigin.x = _cropLayer.frame.origin.x + _cropLayer.frame.size.width - newWidth;
//    }
//
//    //Top-Down bound check
//    if (!(newOrigin.y < _cropLayer.frame.origin.y)) {
//        newOrigin.y = _cropLayer.frame.origin.y;
//    }
//    else if (!((newOrigin.y + newHeight) > (_cropLayer.frame.origin.y + _cropLayer.frame.size.height))) {
//        newOrigin.y = _cropLayer.frame.origin.y + _cropLayer.frame.size.height - newHeight;
//    }
    
    return CGRectIntegral(CGRectMake(0, 0, newWidth, newHeight));
}

//MARK:- Resize Layers After Crop Corner Drag
- (void)resizeLayersAfterCropLayerCornerDrag {
    
    CGRect previousCropLayerFrame = _cropLayer.frame;
    
    [_cropLayer setShouldAnimateResizing:YES];
    _cropLayer.frame = CGRectIntegral(AVMakeRectWithAspectRatioInsideRect(previousCropLayerFrame.size, CGRectMake(kMinimumCropAreaInset, kMinimumCropAreaInset, (self.bounds.size.width - (kMinimumCropAreaInset * 2.0)), (self.bounds.size.height - (kMinimumCropAreaInset * 2.0)))));
    
    CGFloat scale = _cropLayer.frame.size.width / previousCropLayerFrame.size.width;
    
    //Zoom in/out with respect to current crop center
    CGPoint cropLayerCenter = CGPointMake(CGRectGetMidX(previousCropLayerFrame), CGRectGetMidY(previousCropLayerFrame));
    CGPoint imageLayerCurrentZoomCenter = [_imageLayerContainerLayer convertPoint:cropLayerCenter toLayer:_imageLayer];
    
    imageLayerCurrentAnchorPosition = CGPointMake(imageLayerCurrentZoomCenter.x / _imageLayer.frame.size.width, imageLayerCurrentZoomCenter.y / _imageLayer.frame.size.height);
    
    CGRect scaledImageLayerFrame = [self calculateImageLayerScaledFrame:_imageLayer.frame scale:scale anchorPoint:imageLayerCurrentAnchorPosition];
    
    //Move it to center relative to previous crop frame
    CGPoint scaledImageLayerZoomCenter = CGPointMake(imageLayerCurrentAnchorPosition.x * scaledImageLayerFrame.size.width, imageLayerCurrentAnchorPosition.y * scaledImageLayerFrame.size.height);
    CGPoint imageLayerContainerLayerCenter = CGPointMake(CGRectGetMidX(_imageLayerContainerLayer.bounds), CGRectGetMidY(_imageLayerContainerLayer.bounds));
    scaledImageLayerFrame.origin.x = imageLayerContainerLayerCenter.x - scaledImageLayerZoomCenter.x;
    scaledImageLayerFrame.origin.y = imageLayerContainerLayerCenter.y - scaledImageLayerZoomCenter.y;
    
    _imageLayer.frame = scaledImageLayerFrame;
    
    [_cropLayer setShouldAnimateResizing:NO];
}

//MARK:- Image Layer Position Check
- (BOOL)canImageLayerMoveHorizontally:(CGFloat)xDistance {
    
    CGFloat newOriginX = _imageLayer.frame.origin.x + xDistance;
    return (newOriginX <= _cropLayer.frame.origin.x) && (newOriginX + _imageLayer.frame.size.width) >= (_cropLayer.frame.origin.x + _cropLayer.frame.size.width);
}

- (BOOL)canImageLayerMoveVertically:(CGFloat)yDistance {
    
    CGFloat newOriginY = _imageLayer.frame.origin.y + yDistance;
    
    return (newOriginY <= _cropLayer.frame.origin.y) && (newOriginY + _imageLayer.frame.size.height) >= (_cropLayer.frame.origin.y + _cropLayer.frame.size.height);
}

//MARK:- Crop layer Position Check
- (void)canCropLayerResizeHorizontally {
    
}

- (void)isLayerSurroundedByLayer:(CALayer *)layer surroundingLayer:(CALayer *)surroundingLayer {
    
    CGPoint imageLayerUpperLeftPoint = CGPointZero;
    CGPoint imageLayerUpperRightPoint = CGPointMake(_imageLayer.bounds.size.width, 0);
    CGPoint imageLayerLowerLeftPoint = CGPointMake(0, _imageLayer.bounds.size.height);
    CGPoint imageLayerLowerRightPoint = CGPointMake(_imageLayer.bounds.size.width, _imageLayer.bounds.size.height);
    
    CGPoint convertedUpperLeft = [_cropLayer convertPoint:imageLayerUpperLeftPoint fromLayer:_imageLayer];
    CGPoint convertedUpperRight = [_cropLayer convertPoint:imageLayerUpperRightPoint fromLayer:_imageLayer];
    CGPoint convertedLowerLeft = [_cropLayer convertPoint:imageLayerLowerLeftPoint fromLayer:_imageLayer];
    CGPoint convertedLowerRight = [_cropLayer convertPoint:imageLayerLowerRightPoint fromLayer:_imageLayer];
    
    
//    return ;
}

-(BOOL)checkLineIntersection:(CGPoint)p1 :(CGPoint)p2 :(CGPoint)p3 :(CGPoint)p4
{
    CGFloat denominator = (p4.y - p3.y) * (p2.x - p1.x) - (p4.x - p3.x) * (p2.y - p1.y);
    CGFloat ua = (p4.x - p3.x) * (p1.y - p3.y) - (p4.y - p3.y) * (p1.x - p3.x);
    CGFloat ub = (p2.x - p1.x) * (p1.y - p3.y) - (p2.y - p1.y) * (p1.x - p3.x);
    if (denominator < 0) {
        ua = -ua; ub = -ub; denominator = -denominator;
    }
    return (ua > 0.0 && ua <= denominator && ub > 0.0 && ub <= denominator);
}

- (NSValue *)intersectionOfLineFrom:(CGPoint)p1 to:(CGPoint)p2 withLineFrom:(CGPoint)p3 to:(CGPoint)p4
{
    CGFloat d = (p2.x - p1.x)*(p4.y - p3.y) - (p2.y - p1.y)*(p4.x - p3.x);
    if (d == 0)
        return nil; // parallel lines
    CGFloat u = ((p3.x - p1.x)*(p4.y - p3.y) - (p3.y - p1.y)*(p4.x - p3.x))/d;
    CGFloat v = ((p3.x - p1.x)*(p2.y - p1.y) - (p3.y - p1.y)*(p2.x - p1.x))/d;
    if (u < 0.0 || u > 1.0)
        return nil; // intersection point not between p1 and p2
    if (v < 0.0 || v > 1.0)
        return nil; // intersection point not between p3 and p4
    CGPoint intersection;
    intersection.x = p1.x + u * (p2.x - p1.x);
    intersection.y = p1.y + u * (p2.y - p1.y);

    return [NSValue valueWithCGPoint:intersection];
}

//MARK:- Public Methods
- (void)rotateImageLayer:(CGFloat)angle {
    
    imageLayerCurrentAnchorPosition = [self getCurrentImageLayerAnchorPoint];
    
    rotationAngle = angle;
    CGFloat radian = angle * M_PI / 180.0;
    rotationAngle = radian;
    CGFloat deltaAngle = radian - CGAffineTransformGetAngle(_imageLayer.affineTransform);
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    _imageLayer.anchorPoint = imageLayerCurrentAnchorPosition;
    shapeLayer.anchorPoint = imageLayerCurrentAnchorPosition;
    _imageLayer.affineTransform = CGAffineTransformRotate(_imageLayer.affineTransform, deltaAngle);
    shapeLayer.affineTransform = CGAffineTransformRotate(shapeLayer.affineTransform, deltaAngle);
    _imageLayer.anchorPoint = CGPointMake(0.5, 0.5);
    shapeLayer.anchorPoint = CGPointMake(0.5, 0.5);
    [CATransaction commit];

}

- (void)applySkewInImage:(UIImage *)image
{
    if(image)
    {
        CGRect fittedImageRect = AVMakeRectWithAspectRatioInsideRect(_inputImage.size, self.imageLayer.bounds);
        CGFloat scaleX = fittedImageRect.size.width / _inputImage.size.width;
        CGFloat scaleY = fittedImageRect.size.height / _inputImage.size.height;
        CGAffineTransform scaleTransform = CGAffineTransformMakeScale(scaleX, scaleY);
        
        CIImage *filterImage = [[CIImage alloc] initWithImage:image];
        
        CIFilter *perspectiveFilter = [CIFilter filterWithName:@"CIPerspectiveTransform"];
        [perspectiveFilter setValue:filterImage forKey:@"inputImage"];
        CIVector *vectorTL = [CIVector vectorWithCGPoint:imageTopLeftPoint];
        CIVector *vectorTR = [CIVector vectorWithCGPoint:imageTopRightPoint];
        CIVector *vectorBR = [CIVector vectorWithCGPoint:imageBottomRightPoint];
        CIVector *vectorBL = [CIVector vectorWithCGPoint:imageBottomLeftPoint];
        [perspectiveFilter setValue:vectorTL forKey:@"inputTopLeft"];
        [perspectiveFilter setValue:vectorTR forKey:@"inputTopRight"];
        [perspectiveFilter setValue:vectorBR forKey:@"inputBottomRight"];
        [perspectiveFilter setValue:vectorBL forKey:@"inputBottomLeft"];
        filterImage = [perspectiveFilter outputImage];

        CGPoint bl = CGPointApplyAffineTransform(imageBottomLeftPoint, scaleTransform);
        CGPoint tl = CGPointApplyAffineTransform(imageTopLeftPoint, scaleTransform);
        CGPoint tr = CGPointApplyAffineTransform(imageTopRightPoint, scaleTransform);
        CGPoint br = CGPointApplyAffineTransform(imageBottomRightPoint, scaleTransform);
        
        UIBezierPath *bezierPath = [[UIBezierPath alloc] init];
        [bezierPath moveToPoint:bl];
        [bezierPath addLineToPoint:tl];
        [bezierPath addLineToPoint:tr];
        [bezierPath addLineToPoint:br];
        [bezierPath closePath];
        shapeLayer.path = bezierPath.CGPath;

        CGPoint poinstArray[] = {bl, tl, tr, br};
        CGRect smallestRect = CGRectSmallestWithCGPoints(poinstArray, 4);
//        CGAffineTransform rotateTransform = _imageLayer.affineTransform;
//        smallestRect = CGRectApplyAffineTransform(smallestRect, rotateTransform);

        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        shapeLayer.bounds = smallestRect;
        shapeLayer.position = _imageLayer.position;
        _imageLayer.bounds = shapeLayer.bounds;
        _imageLayer.contents = CFBridgingRelease([self.context createCGImage:filterImage fromRect:filterImage.extent]);
        [CATransaction commit];
    }
}

CGRect CGRectSmallestWithCGPoints(CGPoint pointsArray[], int numberOfPoints)
{
    CGFloat greatestXValue = pointsArray[0].x;
    CGFloat greatestYValue = pointsArray[0].y;
    CGFloat smallestXValue = pointsArray[0].x;
    CGFloat smallestYValue = pointsArray[0].y;

    for(int i = 1; i < numberOfPoints; i++)
    {
        CGPoint point = pointsArray[i];
        greatestXValue = MAX(greatestXValue, point.x);
        greatestYValue = MAX(greatestYValue, point.y);
        smallestXValue = MIN(smallestXValue, point.x);
        smallestYValue = MIN(smallestYValue, point.y);
    }

    CGRect rect;
    rect.origin = CGPointMake(smallestXValue, smallestYValue);
    rect.size.width = greatestXValue - smallestXValue;
    rect.size.height = greatestYValue - smallestYValue;

    return CGRectIntegral(rect);
}

- (CGRect)convertedSizeForView:(UIView *)toView fromImage:(UIImage *)fromImage
{
    CGSize imageSize = fromImage.size;
    CGPoint origin = CGPointZero;
    if(imageSize.height > imageSize.width)
    {
        imageSize.height = imageSize.height / imageSize.width * toView.bounds.size.width;
        imageSize.width = toView.bounds.size.width;
        
        origin.y = (toView.bounds.size.height - imageSize.height) / 2.0;
    }
    else
    {
        imageSize.width = imageSize.width / imageSize.height * toView.bounds.size.height;
        imageSize.height = toView.bounds.size.height;
        origin.x = (toView.bounds.size.width - imageSize.width) / 2.0;
    }
    
    return CGRectMake(origin.x, origin.y, imageSize.width, imageSize.height);
}

- (void)skewImageLayerHorizontally:(CGFloat)skewAngle {
    
    skewAngleH = skewAngle / 10.0;
    
    CGFloat value = skewAngle;
    value = value / 200 * _inputImage.size.height;
    if(value >= 0)
    {
        CGPoint currentPoint = imageTopRightPoint;
        currentPoint.y = _inputImage.size.height + value;
        imageTopRightPoint = currentPoint;
        
        currentPoint = imageBottomRightPoint;
        currentPoint.y = (value * -1);
        imageBottomRightPoint = currentPoint;
    }
    else
    {
        CGPoint currentPoint = imageTopLeftPoint;
        currentPoint.y = _inputImage.size.height - value;
        imageTopLeftPoint = currentPoint;
        
        currentPoint = imageBottomLeftPoint;
        currentPoint.y = value;
        imageBottomLeftPoint = currentPoint;
    }
    [self applySkewInImage:_inputImage];
//    [self rotateImageLayer:rotationAngle];
}

- (void)skewImageLayerVertically:(CGFloat)skewAngle {
    
    skewAngleV = skewAngle / 10.0;
    
    CGFloat value = skewAngle;
    value = value / 200 * _inputImage.size.width;
    if(value >= 0)
    {
        CGPoint currentPoint = imageBottomLeftPoint;
        currentPoint.x = (value * -1);
        imageBottomLeftPoint = currentPoint;
        
        currentPoint = imageBottomRightPoint;
        currentPoint.x = _inputImage.size.width + value;
        imageBottomRightPoint = currentPoint;
    }
    else
    {
        CGPoint currentPoint = imageTopLeftPoint;
        currentPoint.x = value;
        imageTopLeftPoint = currentPoint;
        
        currentPoint = imageTopRightPoint;
        currentPoint.x = _inputImage.size.width - value;
        imageTopRightPoint = currentPoint;
    }
    [self applySkewInImage:_inputImage];
//    [self rotateImageLayer:rotationAngle];
}
@end
