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

@implementation BCCropIntersectionInfo

- (instancetype)init
{
    self = [super init];
    if (self) {
        _isIntersected = NO;
        _intersectedPoint = CGPointZero;
        _intersectionPoint = CGPointZero;
    }
    return self;
}

@end

@interface BCCropCanvasView () {
    
    CGPoint initialLocation;
    CGPoint lastLocation;
    
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
    UIBezierPath *bezierPathForShapeLayer;
    CGPoint lastImageLayerPosition;
    CGFloat lastScale;
    BOOL flippedHorizontally;
    BOOL flippedVertically;
    

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
    lastScale = 1.0f;

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
    bezierPathForShapeLayer = [[UIBezierPath alloc] init];
}

- (void)resetImageLayerFrame {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    _imageLayer.frame = _fitImageFrame;
    shapeLayer.bounds = _imageLayer.bounds;
    shapeLayer.position = _imageLayer.position;
    initialImageLayerFrame = _imageLayer.frame;
    [self resetShapeLayerPath];
    [CATransaction commit];
}

- (void)prepareCropLayer {
    
    _cropLayer = [[BCCropLayer alloc] initWithFrame:self.bounds];
    [self.layer addSublayer:_cropLayer];
}

- (void)resetCropLayerFrame {
    _cropLayer.frame = _fitImageFrame;
}

- (void)resetShapeLayerPath {
    
    CGAffineTransform scaleTransform = [self getScaleTransform];
    
    UIBezierPath *tempBezierPath = [UIBezierPath bezierPathWithCGPath:bezierPathForShapeLayer.CGPath];
    [tempBezierPath applyTransform:scaleTransform];
    shapeLayer.path = tempBezierPath.CGPath;

    CGPoint poinstArray[] = {imageBottomLeftPoint, imageTopLeftPoint, imageTopRightPoint, imageBottomRightPoint};
    CGRect smallestRect = CGRectSmallestWithCGPoints(poinstArray, 4);
    smallestRect = CGRectIntegral(CGRectApplyAffineTransform(smallestRect, scaleTransform));
    
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
        lastImageLayerPosition = initialLocation;
        lastLocation = initialLocation;
    }
    
    if (sender.state == UIGestureRecognizerStateChanged) {
        if (cropCornerSelected) {
            CGPoint location = [sender locationInView:sender.view];
            
            CGFloat xPannedDistance = location.x - initialLocation.x;
            CGFloat yPannedDistance = location.y - initialLocation.y;
            
            CGFloat newCropLayerWidth = initialCropLayerFrame.size.width;
            CGFloat newCropLayerHeight = initialCropLayerFrame.size.height;
            
            CGPoint newCropLayerOrigin = initialCropLayerFrame.origin;
            
            if ([self IsIntersectedCropLayer:CGPointMake(xPannedDistance, yPannedDistance) isCropResizing:YES]) {
                location = lastLocation;
                xPannedDistance = location.x - initialLocation.x;
                yPannedDistance = location.y - initialLocation.y;
            }
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
            lastLocation = location;
        }
        else {
            
            CGPoint location = [sender locationInView:sender.view];
            CGFloat deltaWidth = location.x - lastImageLayerPosition.x;
            CGFloat deltaHeight = location.y - lastImageLayerPosition.y;
            CGPoint newPosition = _imageLayer.position;
            if(![self IsIntersectedCropLayer:CGPointMake(deltaWidth, deltaHeight) isCropResizing:NO])
            {
                newPosition.x = newPosition.x + deltaWidth;
                newPosition.y = newPosition.y + deltaHeight;
            }

            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            _imageLayer.position = newPosition;
            shapeLayer.position = newPosition;
            [CATransaction commit];
            lastImageLayerPosition = location;
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
//    NSLog(@"iswithinscroll %ld",[self IsInsideCropLayer:CGPointZero]);
//    if (![self isWithinScrollArea]) {
//        return;
//    }
    
    if(sender.state == UIGestureRecognizerStateBegan) {
        initialLocation = [sender locationInView:sender.view];
        initialImageLayerFrame = _imageLayer.bounds;
        
        //Zoom in/out with respect to current crop center / imagelayer anchor
        imageLayerCurrentAnchorPosition = [self getCurrentImageLayerAnchorPoint];
        zoomScale = 1.0;
    }
    
    if (sender.state == UIGestureRecognizerStateChanged) {
        CGAffineTransform lastTransform = _imageLayer.affineTransform;
        CGFloat deltaScale = sender.scale - zoomScale;
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            shapeLayer.anchorPoint = imageLayerCurrentAnchorPosition;
        shapeLayer.affineTransform = CGAffineTransformScale(shapeLayer.affineTransform, 1.0f + deltaScale,1.0f + deltaScale);
            shapeLayer.anchorPoint = CGPointMake(0.5, 0.5);
            [CATransaction commit];
            zoomScale = sender.scale;

        if([self IsIntersectedCropLayer:CGPointZero isCropResizing:NO])
        {
            imageLayerCurrentAnchorPosition = [self getCurrentImageLayerAnchorPoint];
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            shapeLayer.anchorPoint = imageLayerCurrentAnchorPosition;
            _imageLayer.anchorPoint = imageLayerCurrentAnchorPosition;
            _imageLayer.affineTransform = lastTransform;
            shapeLayer.affineTransform = lastTransform;
            _imageLayer.anchorPoint = CGPointMake(0.5, 0.5);
            shapeLayer.anchorPoint = CGPointMake(0.5, 0.5);
//            if([self IsIntersectedCropLayer:CGPointZero])
//                [self resizeImageLayerOnDemand];
            [CATransaction commit];

        }else{
            imageLayerCurrentAnchorPosition = [self getCurrentImageLayerAnchorPoint];
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            _imageLayer.anchorPoint = imageLayerCurrentAnchorPosition;
            _imageLayer.affineTransform = shapeLayer.affineTransform;
            _imageLayer.anchorPoint = CGPointMake(0.5, 0.5);
//            if([self IsIntersectedCropLayer:CGPointZero])
//                [self resizeImageLayerOnDemand];
            [CATransaction commit];
        }
    }
    
    if (sender.state == UIGestureRecognizerStateEnded){
        zoomScale = 1.0f;
        sender.scale = 1.0f;
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
    CGFloat translationX = (frame.size.width - newWidth) * anchor.x;
    CGFloat translationY = (frame.size.height - newHeight) * anchor.y;

    CGPoint newOrigin = CGPointMake(frame.origin.x + translationX, frame.origin.y + translationY);

    //Left-Right bound check
    if (!(newOrigin.x < _cropLayer.frame.origin.x)) {
        newOrigin.x = _cropLayer.frame.origin.x;
    }
    else if (!((newOrigin.x + newWidth) > (_cropLayer.frame.origin.x + _cropLayer.frame.size.width))) {
        newOrigin.x = _cropLayer.frame.origin.x + _cropLayer.frame.size.width - newWidth;
    }

    //Top-Down bound check
    if (!(newOrigin.y < _cropLayer.frame.origin.y)) {
        newOrigin.y = _cropLayer.frame.origin.y;
    }
    else if (!((newOrigin.y + newHeight) > (_cropLayer.frame.origin.y + _cropLayer.frame.size.height))) {
        newOrigin.y = _cropLayer.frame.origin.y + _cropLayer.frame.size.height - newHeight;
    }
    
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
    
    CGPoint currentPosition = _imageLayer.position;
    _imageLayer.bounds = scaledImageLayerFrame;
    shapeLayer.bounds = _imageLayer.bounds;
    _imageLayer.position = currentPosition;
    shapeLayer.position = _imageLayer.position;
    _fitImageFrame = scaledImageLayerFrame;
    [self resetShapeLayerPath];
    
    
    [_cropLayer setShouldAnimateResizing:NO];
}

//MARK:- Crop layer Position Check
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
    if([self IsIntersectedCropLayer:CGPointZero isCropResizing:NO])
        [self resizeImageLayerOnDemand];
    [CATransaction commit];
}

- (void)applySkewInImage:(UIImage *)image
{
    if(image)
    {
        CIImage *filterImage = [[CIImage alloc] initWithImage:image];
        if (flippedHorizontally) {
            filterImage = [filterImage imageByApplyingTransform:CGAffineTransformScale(CGAffineTransformIdentity, -1, 1)];
        }
        if (flippedVertically) {
            filterImage = [filterImage imageByApplyingTransform:CGAffineTransformScale(CGAffineTransformIdentity, 1, -1)];

        }
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

        [bezierPathForShapeLayer removeAllPoints];
        [bezierPathForShapeLayer moveToPoint:imageBottomLeftPoint];
        [bezierPathForShapeLayer addLineToPoint:imageTopLeftPoint];
        [bezierPathForShapeLayer addLineToPoint:imageTopRightPoint];
        [bezierPathForShapeLayer addLineToPoint:imageBottomRightPoint];
        [bezierPathForShapeLayer closePath];
        
        CGAffineTransform scaleTransform = [self getScaleTransform];
        UIBezierPath *tempBezierPath = [UIBezierPath bezierPathWithCGPath:bezierPathForShapeLayer.CGPath];
        [tempBezierPath applyTransform:scaleTransform];
        shapeLayer.path = tempBezierPath.CGPath;
        
        CGPoint poinstArray[] = {imageBottomLeftPoint, imageTopLeftPoint, imageTopRightPoint, imageBottomRightPoint};
        CGRect smallestRect = CGRectSmallestWithCGPoints(poinstArray, 4);
        smallestRect = CGRectApplyAffineTransform(smallestRect, scaleTransform);

        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        shapeLayer.bounds = smallestRect;
        shapeLayer.position = _imageLayer.position;
        _imageLayer.bounds = shapeLayer.bounds;
        _imageLayer.contents = CFBridgingRelease([self.context createCGImage:filterImage fromRect:filterImage.extent]);
        if([self IsIntersectedCropLayer:CGPointZero isCropResizing:NO])
            [self resizeImageLayerOnDemand];
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

    return rect;
}

- (void)skewImageLayerHorizontally:(CGFloat)skewAngle {
    
    skewAngleH = skewAngle / 10.0;
    
    CGFloat value = skewAngle;
    value = value / 200 * _inputImage.size.height;
    if(value >= 0)
    {
        CGPoint currentPoint = imageTopRightPoint;
        currentPoint.y = floorf(_inputImage.size.height + value);
        imageTopRightPoint = currentPoint;
        
        currentPoint = imageBottomRightPoint;
        currentPoint.y = floorf(value * -1);
        imageBottomRightPoint = currentPoint;
    }
    else
    {
        CGPoint currentPoint = imageTopLeftPoint;
        currentPoint.y = floorf(_inputImage.size.height - value);
        imageTopLeftPoint = currentPoint;
        
        currentPoint = imageBottomLeftPoint;
        currentPoint.y = floorf(value);
        imageBottomLeftPoint = currentPoint;
    }
    [self applySkewInImage:_inputImage];
}

- (void)skewImageLayerVertically:(CGFloat)skewAngle {
    
    skewAngleV = skewAngle / 10.0;
    
    CGFloat value = skewAngle;
    value = value / 200 * _inputImage.size.width;
    if(value >= 0)
    {
        CGPoint currentPoint = imageBottomLeftPoint;
        currentPoint.x = floorf(value * -1);
        imageBottomLeftPoint = currentPoint;
        
        currentPoint = imageBottomRightPoint;
        currentPoint.x = floorf(_inputImage.size.width + value);
        imageBottomRightPoint = currentPoint;
    }
    else
    {
        CGPoint currentPoint = imageTopLeftPoint;
        currentPoint.x = floorf(value);
        imageTopLeftPoint = currentPoint;
        
        currentPoint = imageTopRightPoint;
        currentPoint.x = floorf(_inputImage.size.width - value);
        imageTopRightPoint = currentPoint;
    }
    [self applySkewInImage:_inputImage];
}

- (BOOL)IsIntersectedCropLayer:(CGPoint)newPoint isCropResizing:(BOOL)isCropResizing
{
    BOOL bRet = NO;
    NSMutableArray *cropPoints = [NSMutableArray array];
    
    CGRect cropFrame = _cropLayer.frame;
    
    if(isCropResizing) {
        
        CGFloat possibleCropLayerWidth = initialCropLayerFrame.size.width;
        CGFloat possibleCropLayerHeight = initialCropLayerFrame.size.height;
        
        CGPoint possibleCropLayerOrigin = initialCropLayerFrame.origin;
        
        
        switch (selectedCropCorner) {
                
            case BCCropCornerTypeUpperLeft: {
                possibleCropLayerWidth = possibleCropLayerWidth - newPoint.x;
                possibleCropLayerHeight = possibleCropLayerHeight - newPoint.y;
                
                if (possibleCropLayerWidth < kMinimumCropAreaSide) {
                    possibleCropLayerWidth = kMinimumCropAreaSide;
                    newPoint.x = initialCropLayerFrame.size.width - kMinimumCropAreaSide;
                }
                if (possibleCropLayerHeight < kMinimumCropAreaSide) {
                    possibleCropLayerHeight = kMinimumCropAreaSide;
                    newPoint.y = initialCropLayerFrame.size.height - kMinimumCropAreaSide;
                }
                
                possibleCropLayerOrigin.x = possibleCropLayerOrigin.x + newPoint.x;
                possibleCropLayerOrigin.y = possibleCropLayerOrigin.y + newPoint.y;
                break;
            }
                
            case BCCropCornerTypeUpperRight: {
                possibleCropLayerWidth = possibleCropLayerWidth + newPoint.x;
                possibleCropLayerHeight = possibleCropLayerHeight - newPoint.y;
                
                if (possibleCropLayerWidth < kMinimumCropAreaSide) {
                    possibleCropLayerWidth = kMinimumCropAreaSide;
                }
                if (possibleCropLayerHeight < kMinimumCropAreaSide) {
                    possibleCropLayerHeight = kMinimumCropAreaSide;
                    newPoint.y = initialCropLayerFrame.size.height - kMinimumCropAreaSide;
                }
                
                possibleCropLayerOrigin.y = possibleCropLayerOrigin.y + newPoint.y;
                
                break;
            }
                
            case BCCropCornerTypeLowerLeft: {
                possibleCropLayerWidth = possibleCropLayerWidth - newPoint.x;
                possibleCropLayerHeight = possibleCropLayerHeight + newPoint.y;
                
                if (possibleCropLayerWidth < kMinimumCropAreaSide) {
                    possibleCropLayerWidth = kMinimumCropAreaSide;
                    newPoint.x = initialCropLayerFrame.size.width - kMinimumCropAreaSide;
                }
                if (possibleCropLayerHeight < kMinimumCropAreaSide) {
                    possibleCropLayerHeight = kMinimumCropAreaSide;
                }
                
                possibleCropLayerOrigin.x = possibleCropLayerOrigin.x + newPoint.x;
                break;
            }
                
            case BCCropCornerTypeLowerRight: {
                
                possibleCropLayerWidth = possibleCropLayerWidth + newPoint.x;
                possibleCropLayerHeight = possibleCropLayerHeight + newPoint.y;
                
                if (possibleCropLayerWidth < kMinimumCropAreaSide) {
                    possibleCropLayerWidth = kMinimumCropAreaSide;
                }
                if (possibleCropLayerHeight < kMinimumCropAreaSide) {
                    possibleCropLayerHeight = kMinimumCropAreaSide;
                }
                
                break;
            }
                
            default: {
                break;
            }
        }
        
        cropFrame.origin = possibleCropLayerOrigin;
        cropFrame.size = CGSizeMake(possibleCropLayerWidth, possibleCropLayerHeight);
    }
    
    CGPoint tl = cropFrame.origin;
    [cropPoints addObject:[NSValue valueWithCGPoint:tl]];
    CGPoint tr = CGPointMake(cropFrame.origin.x + cropFrame.size.width, cropFrame.origin.y);
    [cropPoints addObject:[NSValue valueWithCGPoint:tr]];
    CGPoint br = CGPointMake(cropFrame.origin.x + cropFrame.size.width, cropFrame.origin.y + cropFrame.size.height);
    [cropPoints addObject:[NSValue valueWithCGPoint:br]];
    CGPoint bl = CGPointMake(cropFrame.origin.x, cropFrame.origin.y + cropFrame.size.height);
    [cropPoints addObject:[NSValue valueWithCGPoint:bl]];
    
    for(int index = 0; index < cropPoints.count; index++)
    {
        CGPoint p1 = [cropPoints[index] CGPointValue];
        CGPoint p2 = [cropPoints[(index < 3 ? index + 1 : 0)] CGPointValue];
        
        BCCropIntersectionInfo *info = [self checkCropPointsInterSection:p1 point2:p2 translation:newPoint isCropResizing:isCropResizing];
        bRet = info.isIntersected;
        if(info.isIntersected)
            break;
    }
    return bRet;
}

- (NSMutableArray *)getCropIntersectionsFromTranslation:(CGPoint)translation
{
    NSMutableArray *cropPoints = [NSMutableArray array];
    
    CGPoint tl = _cropLayer.frame.origin;
    [cropPoints addObject:[NSValue valueWithCGPoint:tl]];
    CGPoint tr = CGPointMake(_cropLayer.frame.origin.x + _cropLayer.frame.size.width, _cropLayer.frame.origin.y);
    [cropPoints addObject:[NSValue valueWithCGPoint:tr]];
    CGPoint br = CGPointMake(_cropLayer.frame.origin.x + _cropLayer.frame.size.width, _cropLayer.frame.origin.y + _cropLayer.frame.size.height);
    [cropPoints addObject:[NSValue valueWithCGPoint:br]];
    CGPoint bl = CGPointMake(_cropLayer.frame.origin.x, _cropLayer.frame.origin.y + _cropLayer.frame.size.height);
    [cropPoints addObject:[NSValue valueWithCGPoint:bl]];
    
    NSMutableArray *resultArray = [NSMutableArray new];
    for(int index = 0; index < cropPoints.count; index++)
    {
        CGPoint p1 = [cropPoints[index] CGPointValue];
        CGPoint p2 = [cropPoints[(index < 3 ? index + 1 : 0)] CGPointValue];
        
        BCCropIntersectionInfo *info = [self checkCropPointsInterSection:p1 point2:p2 translation:translation isCropResizing:NO];
        [resultArray addObject:info];
    }
    return resultArray;
}

- (BCCropIntersectionInfo *)checkCropPointsInterSection:(CGPoint)p1 point2:(CGPoint)p2 translation:(CGPoint)translation isCropResizing:(BOOL)isCropResizing {
    
    NSMutableArray *shapePoints = [NSMutableArray array];
    CGPoint topLeft = [self converPointFromLayertoImage:imageTopLeftPoint];
    CGPoint topRight = [self converPointFromLayertoImage:imageTopRightPoint];
    CGPoint bottomLeft = [self converPointFromLayertoImage:imageBottomLeftPoint];
    CGPoint bottomRight = [self converPointFromLayertoImage:imageBottomRightPoint];
    
    topLeft = [shapeLayer convertPoint:topLeft toLayer:_imageLayerContainerLayer];
    if (!isCropResizing) {
    topLeft.x = topLeft.x + translation.x;
    topLeft.y = topLeft.y + translation.y;
    }
    [shapePoints addObject:[NSValue valueWithCGPoint:topLeft]];
    
    topRight = [shapeLayer convertPoint:topRight toLayer:_imageLayerContainerLayer];
    if (!isCropResizing) {
    topRight.x = topRight.x + translation.x;
    topRight.y = topRight.y + translation.y;
    }
    [shapePoints addObject:[NSValue valueWithCGPoint:topRight]];
    
    bottomRight = [shapeLayer convertPoint:bottomRight toLayer:_imageLayerContainerLayer];
    if (!isCropResizing) {
    bottomRight.x = bottomRight.x + translation.x;
    bottomRight.y = bottomRight.y + translation.y;
    }
    [shapePoints addObject:[NSValue valueWithCGPoint:bottomRight]];
    
    bottomLeft = [shapeLayer convertPoint:bottomLeft toLayer:_imageLayerContainerLayer];
    if (!isCropResizing) {
    bottomLeft.x = bottomLeft.x + translation.x;
    bottomLeft.y = bottomLeft.y + translation.y;
    }
    [shapePoints addObject:[NSValue valueWithCGPoint:bottomLeft]];
    
    bool isIntersected = NO;
    CGPoint intersectionPoint = CGPointZero;
    CGPoint intersectedPoint = CGPointZero;
    for (int j = 0; j < shapePoints.count; j++) {
        
        int s1 = j;
        int s2;
        if (s1 == shapePoints.count - 1) {
            s2 = 0;
        }
        else {
            s2 = s1 + 1;
        }
        
        CGPoint p3 = [shapePoints[s1] CGPointValue];
        CGPoint p4 = [shapePoints[s2] CGPointValue];
        
        if ([self intersectionOfLineFrom:p3 to:p4 withLineFrom:p1 to:p2]) {
            
            isIntersected = YES;
            intersectionPoint = [[self intersectionOfLineFrom:p3 to:p4 withLineFrom:p1 to:p2] CGPointValue];
            intersectedPoint = p1;
            
            if (distanceBetweenPoints(intersectionPoint, p1) > distanceBetweenPoints(intersectionPoint, p2)) {
                intersectedPoint = p2;
            }
            break;
        }
    }
    
    BCCropIntersectionInfo *info = [[BCCropIntersectionInfo alloc] init];
    info.isIntersected = isIntersected;
    info.intersectionPoint = intersectionPoint;
    info.intersectedPoint = intersectedPoint;
    return info;
}

- (void)resizeImageLayerOnDemand
{
    CGRect expectedRect = AVMakeRectWithAspectRatioInsideRect(_cropLayer.bounds.size, _imageLayer.frame);
    CGPoint currentPosition = _imageLayer.position;
    CGRect imageLayerRect = _imageLayer.bounds;
    imageLayerRect.size = expectedRect.size;
    [CATransaction begin];
    [CATransaction setDisableActions:NO];
    shapeLayer.bounds = imageLayerRect;
    _imageLayer.bounds = shapeLayer.bounds;
    _imageLayer.position = currentPosition;
    shapeLayer.position = _imageLayer.position;
    _fitImageFrame = imageLayerRect;
    [self resetShapeLayerPath];
    [CATransaction commit];
}

-(CGPoint)converPointFromLayertoImage:(CGPoint)inputPoint{
    CGAffineTransform scaleTransform = [self getScaleTransform];
    CGPoint convertedPoint = CGPointApplyAffineTransform(inputPoint, scaleTransform);
    return convertedPoint;
}

- (CGAffineTransform)getScaleTransform
{
    CGRect fittedImageRect = CGRectIntegral(AVMakeRectWithAspectRatioInsideRect(_inputImage.size, _fitImageFrame));
    CGFloat scaleX = fittedImageRect.size.width / _inputImage.size.width;
    CGFloat scaleY = fittedImageRect.size.height / _inputImage.size.height;
    CGAffineTransform scaleTransform = CGAffineTransformMakeScale(scaleX, scaleY);
    return scaleTransform;
}

-(void)flipImageHorizontal{
    flippedHorizontally = !flippedHorizontally;
    [self applySkewInImage:_inputImage];
}

-(void)flipImageVertical{
    flippedVertically = !flippedVertically;
    [self applySkewInImage:_inputImage];
}


@end
