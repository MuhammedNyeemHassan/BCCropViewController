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
#import "NCCropDataModel.h"
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
    UIGestureRecognizerState pinchState;
    CGPoint initialImageLayerPosition;
    NCCropDataModel * cropDataModel;
    CGFloat skewHorizontalValue;
    CGFloat skewVerticalValue;
}
@property (strong, nonatomic) CIContext *context;

@property (strong, nonatomic) CALayer *imageLayer;
@property (strong, nonatomic) BCCropLayer *cropLayer;

@property (strong, nonatomic) UIPanGestureRecognizer *pan;
@property (strong, nonatomic) UIPinchGestureRecognizer *pinch;

@property CGRect fitImageFrame;
@property CGRect lastFitImageFrame;

@property CGFloat aspectRatioWidth;
@property CGFloat aspectRatioHeight;
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
    [self prepareImageLayer];
    [self prepareShapeLayer];
    [self prepareCropLayer];
    [self prepareGestureRecognizers];
    lastScale = 1.0f;
    cropDataModel = [[NCCropDataModel alloc] init];

}

- (void)layoutSubviews {
    [super layoutSubviews];
    
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
    skewHorizontalValue = 0.0;
    skewVerticalValue = 0.0;
    [self applySkewInImage:_inputImage];
}

- (void)setCropAspectRatio:(NSString *)cropAspectRatio {
    _cropAspectRatio = cropAspectRatio;
    
    if (_cropAspectRatio.length > 0) {
        
        NSArray *elements = [_cropAspectRatio componentsSeparatedByString:@":"];
        _aspectRatioWidth = (CGFloat)[[elements firstObject] floatValue];
        _aspectRatioHeight = (CGFloat)[[elements lastObject] floatValue];
        
        _cropLayer.frame = CGRectIntegral(AVMakeRectWithAspectRatioInsideRect(CGSizeMake(_aspectRatioWidth, _aspectRatioHeight), CGRectMake(kMinimumCropAreaInset, kMinimumCropAreaInset, (self.bounds.size.width - (kMinimumCropAreaInset * 2.0)), (self.bounds.size.height - (kMinimumCropAreaInset * 2.0)))));
        
        CGPoint center = _cropLayer.position;
        if([self IsIntersectedCropLayer:CGPointZero isCropResizing:NO])
        {
            // position scroll view
            CGAffineTransform scaleTransform = [self getScaleTransform];
            UIBezierPath *tempBezierPath = [UIBezierPath bezierPathWithCGPath:bezierPathForShapeLayer.CGPath];
            [tempBezierPath applyTransform:scaleTransform];
            CGRect boundingBox = CGPathGetBoundingBox(tempBezierPath.CGPath);
            
            
            CGRect fittedImageRect = CGRectIntegral(AVMakeRectWithAspectRatioInsideRect(_inputImage.size, _cropLayer.bounds));
            CGFloat scaleX = fittedImageRect.size.width / _inputImage.size.width;
            CGFloat scaleY = fittedImageRect.size.height / _inputImage.size.height;
            CGAffineTransform scale = CGAffineTransformMakeScale(scaleX, scaleY);
            CGFloat widthDiff = _imageLayer.frame.size.width - boundingBox.size.width;
            CGFloat heightDiff = _imageLayer.frame.size.height - boundingBox.size.height;
            
            widthDiff = (MAX(imageBottomRightPoint.x, imageTopRightPoint.x) - _inputImage.size.width) * 2;
            heightDiff = (MAX(imageTopLeftPoint.y, imageTopRightPoint.y) - _inputImage.size.height) * 2;
            
            CGSize sizeDiff = CGSizeMake(widthDiff, heightDiff);
            sizeDiff = CGSizeApplyAffineTransform(sizeDiff, scale);
            sizeDiff = CGSizeZero;
            CGFloat width = fabs(cos(rotationAngle)) * (_cropLayer.frame.size.width + sizeDiff.width) + fabs(sin(rotationAngle)) * (_cropLayer.frame.size.height + sizeDiff.height);
            CGFloat height = fabs(sin(rotationAngle)) * (_cropLayer.frame.size.width + sizeDiff.width) + fabs(cos(rotationAngle)) * (_cropLayer.frame.size.height + sizeDiff.height);
            if(_inputImage.size.width > _inputImage.size.height)
                width = _inputImage.size.width / _inputImage.size.height * height;
            else
                height = _inputImage.size.height / _inputImage.size.width * width;


            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            CGRect newBounds = CGRectMake(0, 0, width, height);
            _imageLayer.bounds = newBounds;
            shapeLayer.bounds = newBounds;
            _imageLayer.position = center;
            shapeLayer.position = center;
            _fitImageFrame = newBounds;
            [self resetShapeLayerPath];
            [CATransaction commit];
        }
        
//        if (_cropLayer.frame.origin.x < _imageLayer.frame.origin.x) {
//
//            CGFloat widthOffset = _cropLayer.frame.size.width - _imageLayer.frame.size.width;
//
//            CGPoint currentPosition = _imageLayer.position;
//            CGSize currentSize = _imageLayer.bounds.size;
//
//            CGFloat newWidth = _imageLayer.bounds.size.width + widthOffset;
//            CGFloat newHeight = newWidth * currentSize.height / currentSize.width;
//
//            _imageLayer.bounds = CGRectMake(0, 0, newWidth, newHeight);
//            _imageLayer.position = currentPosition;
//        }
//
//        if (_cropLayer.frame.origin.y < _imageLayer.frame.origin.y) {
//
//            CGFloat heightOffset = _cropLayer.frame.size.height - _imageLayer.frame.size.height;
//
//            CGPoint currentPosition = _imageLayer.position;
//            CGSize currentSize = _imageLayer.bounds.size;
//
//            CGFloat newHeight = _imageLayer.bounds.size.height + heightOffset;
//            CGFloat newWidth = newHeight * currentSize.width / currentSize.height;
//
//            _imageLayer.bounds = CGRectMake(0, 0, newWidth, newHeight);
//            _imageLayer.position = currentPosition;
//        }
    }
    else {
        [self resetCropLayerFrame];
    }
}

//MARK:- Prepare Layers
- (void)prepareImageLayer {
    
    _imageLayer = [[CALayer alloc] init];
    _imageLayer.contentsGravity = kCAGravityResize;
    _imageLayer.shouldRasterize = YES;
    _imageLayer.rasterizationScale = UIScreen.mainScreen.scale;
    [self.layer addSublayer:_imageLayer];
    rotationAngle = 0;
}

- (void)prepareShapeLayer {
    
    shapeLayer = [CAShapeLayer layer];
    shapeLayer.shouldRasterize = YES;
    shapeLayer.rasterizationScale = UIScreen.mainScreen.scale;
    shapeLayer.geometryFlipped = YES;
    [self.layer addSublayer:shapeLayer];
    
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
    initialImageLayerPosition = _imageLayer.position;
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

//    CGPoint poinstArray[] = {imageBottomLeftPoint, imageTopLeftPoint, imageTopRightPoint, imageBottomRightPoint};
//    CGRect smallestRect = CGRectSmallestWithCGPoints(poinstArray, 4);
//    smallestRect = CGRectIntegral(CGRectApplyAffineTransform(smallestRect, scaleTransform));
    CGRect boundingBox = CGPathGetBoundingBox(shapeLayer.path);
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    shapeLayer.bounds = boundingBox;
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
    NSLog(@"PAN senderState: %d", sender.state);
    
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
            CGFloat deltaWidth = location.x - lastLocation.x;
            CGFloat deltaHeight = location.y - lastLocation.y;
            CGRect cropRect = _cropLayer.frame;
            
            CGFloat changedWidth = 0;
            CGFloat changedHeight = 0;
            if([self IsCropCornerPanningPossibleAtX:deltaWidth])
            {
                changedWidth = deltaWidth;
            }
            
            if([self IsCropCornerPanningPossibleAtY:deltaHeight])
            {
                changedHeight = deltaHeight;
            }
            
            switch (selectedCropCorner) {
                case BCCropCornerTypeUpperLeft:
                {
                    cropRect.size.width -= changedWidth;
                    cropRect.size.height -= changedHeight;
                    if (cropRect.size.width < kMinimumCropAreaSide) {
                        cropRect.size.width = kMinimumCropAreaSide;
                        changedWidth = _cropLayer.frame.size.width - kMinimumCropAreaSide;
                    }
                    if (cropRect.size.height < kMinimumCropAreaSide) {
                        cropRect.size.height = kMinimumCropAreaSide;
                        changedHeight = _cropLayer.frame.size.height - kMinimumCropAreaSide;
                    }
                    cropRect.origin.x += changedWidth;
                    cropRect.origin.y += changedHeight;
                    break;
                }
                case BCCropCornerTypeUpperRight:
                {
                    cropRect.size.width += changedWidth;
                    cropRect.size.height -= changedHeight;
                    if (cropRect.size.width < kMinimumCropAreaSide) {
                        cropRect.size.width = kMinimumCropAreaSide;
                    }
                    if (cropRect.size.height < kMinimumCropAreaSide) {
                        cropRect.size.height = kMinimumCropAreaSide;
                        changedHeight = _cropLayer.frame.size.height - kMinimumCropAreaSide;
                    }
                    cropRect.origin.y += changedHeight;
                    break;
                }
                case BCCropCornerTypeLowerRight:
                {
                    cropRect.size.width += changedWidth;
                    cropRect.size.height += changedHeight;
                    if (cropRect.size.width < kMinimumCropAreaSide) {
                        cropRect.size.width = kMinimumCropAreaSide;
                    }
                    if (cropRect.size.height < kMinimumCropAreaSide) {
                        cropRect.size.height = kMinimumCropAreaSide;
                    }
                    break;
                }
                case BCCropCornerTypeLowerLeft:
                {
                    cropRect.size.width -= changedWidth;
                    cropRect.size.height += changedHeight;
                    if (cropRect.size.width < kMinimumCropAreaSide) {
                        cropRect.size.width = kMinimumCropAreaSide;
                        changedWidth = _cropLayer.frame.size.width - kMinimumCropAreaSide;
                    }
                    if (cropRect.size.height < kMinimumCropAreaSide) {
                        cropRect.size.height = kMinimumCropAreaSide;
                    }
                    cropRect.origin.x += changedWidth;
                    break;
                }
                case BCCropCornerTypeNone:
                    break;
            }
            
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            _cropLayer.frame = cropRect;
            [CATransaction commit];
            lastLocation = location;
        }
        else {
            
            CGPoint location = [sender locationInView:sender.view];
            CGFloat deltaWidth = location.x - lastImageLayerPosition.x;
            CGFloat deltaHeight = location.y - lastImageLayerPosition.y;
            CGPoint newPosition = _imageLayer.position;
            
            if([self IsImagePanningPossibleAtX:deltaWidth])
            {
                newPosition.x += deltaWidth;
            }
            
            if([self IsImagePanningPossibleAtX:deltaHeight])
            {
                newPosition.y += deltaHeight;
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

- (BOOL)IsCropCornerPanningPossibleAtX:(CGFloat)xDiff
{
    CGPoint topLeft = [self converPointFromLayertoImage:imageTopLeftPoint];
    CGPoint topRight = [self converPointFromLayertoImage:imageTopRightPoint];
    CGPoint bottomRight = [self converPointFromLayertoImage:imageBottomRightPoint];
    CGPoint bottomLeft = [self converPointFromLayertoImage:imageBottomLeftPoint];

    CGRect nextCropRect = _cropLayer.frame;
    switch (selectedCropCorner) {
        case BCCropCornerTypeUpperLeft:
        case BCCropCornerTypeLowerLeft:
        {
            nextCropRect.origin.x += xDiff;
            break;
        }
        case BCCropCornerTypeUpperRight:
        case BCCropCornerTypeLowerRight:
        {
            nextCropRect.size.width += xDiff;
            break;
        }
        case BCCropCornerTypeNone:
            break;
    }
    
    bool topLeftIntersects = LineIntersectsRect(topLeft, topRight, nextCropRect);
    bool topRightIntersects = LineIntersectsRect(topRight, bottomRight, nextCropRect);
    bool bottomLeftIntersects = LineIntersectsRect(bottomRight, bottomLeft, nextCropRect);
    bool bottomRightIntersects = LineIntersectsRect(bottomLeft, topLeft, nextCropRect);
    
    return (!topLeftIntersects && !topRightIntersects && !bottomRightIntersects && !bottomLeftIntersects);
}

- (BOOL)IsCropCornerPanningPossibleAtY:(CGFloat)yDiff
{
    CGPoint topLeft = [self converPointFromLayertoImage:imageTopLeftPoint];
    CGPoint topRight = [self converPointFromLayertoImage:imageTopRightPoint];
    CGPoint bottomLeft = [self converPointFromLayertoImage:imageBottomLeftPoint];
    CGPoint bottomRight = [self converPointFromLayertoImage:imageBottomRightPoint];
    
    CGRect nextCropRect = _cropLayer.frame;
    switch (selectedCropCorner) {
        case BCCropCornerTypeUpperLeft:
        case BCCropCornerTypeUpperRight:
        {
            nextCropRect.origin.y += yDiff;
            break;
        }
        case BCCropCornerTypeLowerLeft:
        case BCCropCornerTypeLowerRight:
        {
            nextCropRect.size.height += yDiff;
            break;
        }
        case BCCropCornerTypeNone:
            break;
    }
    
    bool topLeftIntersects = LineIntersectsRect(topLeft, topRight, nextCropRect);
    bool topRightIntersects = LineIntersectsRect(topRight, bottomRight, nextCropRect);
    bool bottomLeftIntersects = LineIntersectsRect(bottomRight, bottomLeft, nextCropRect);
    bool bottomRightIntersects = LineIntersectsRect(bottomLeft, topLeft, nextCropRect);
    
    return (!topLeftIntersects && !topRightIntersects && !bottomRightIntersects && !bottomLeftIntersects);
}


- (BOOL)IsImagePanningPossibleAtX:(CGFloat)xDiff
{
    CGPoint topLeft = [self converPointFromLayertoImage:imageTopLeftPoint];
    CGPoint topRight = [self converPointFromLayertoImage:imageTopRightPoint];
    CGPoint bottomLeft = [self converPointFromLayertoImage:imageBottomLeftPoint];
    CGPoint bottomRight = [self converPointFromLayertoImage:imageBottomRightPoint];
    
    CGPoint nextTopLeft = CGPointMake(topLeft.x + xDiff, topLeft.y);
    CGPoint nextTopRight = CGPointMake(topRight.x + xDiff, topRight.y);
    CGPoint nextBottomLeft = CGPointMake(bottomLeft.x + xDiff, bottomLeft.y);
    CGPoint nextBottomRight = CGPointMake(bottomRight.x + xDiff, bottomRight.y);
    
    bool topLeftIntersects = LineIntersectsRect(nextTopLeft, nextTopRight, _cropLayer.frame);
    bool topRightIntersects = LineIntersectsRect(nextTopRight, nextBottomRight, _cropLayer.frame);
    bool bottomLeftIntersects = LineIntersectsRect(nextBottomRight, nextBottomLeft, _cropLayer.frame);
    bool bottomRightIntersects = LineIntersectsRect(nextBottomLeft, nextTopLeft, _cropLayer.frame);
    
    return (!topLeftIntersects && !topRightIntersects && !bottomRightIntersects && !bottomLeftIntersects);
}

- (BOOL)IsImagePanningPossibleAtY:(CGFloat)yDiff
{
    CGPoint topLeft = [self converPointFromLayertoImage:imageTopLeftPoint];
    CGPoint topRight = [self converPointFromLayertoImage:imageTopRightPoint];
    CGPoint bottomLeft = [self converPointFromLayertoImage:imageBottomLeftPoint];
    CGPoint bottomRight = [self converPointFromLayertoImage:imageBottomRightPoint];
    
    CGPoint nextTopLeft = CGPointMake(topLeft.x, topLeft.y + yDiff);
    CGPoint nextTopRight = CGPointMake(topRight.x, topRight.y + yDiff);
    CGPoint nextBottomLeft = CGPointMake(bottomLeft.x, bottomLeft.y + yDiff);
    CGPoint nextBottomRight = CGPointMake(bottomRight.x, bottomRight.y + yDiff);
    
    bool topLeftIntersects = LineIntersectsRect(nextTopLeft, nextTopRight, _cropLayer.frame);
    bool topRightIntersects = LineIntersectsRect(nextTopRight, nextBottomRight, _cropLayer.frame);
    bool bottomLeftIntersects = LineIntersectsRect(nextBottomRight, nextBottomLeft, _cropLayer.frame);
    bool bottomRightIntersects = LineIntersectsRect(nextBottomLeft, nextTopLeft, _cropLayer.frame);
    
    return (!topLeftIntersects && !topRightIntersects && !bottomRightIntersects && !bottomLeftIntersects);
}

- (void)pinchGestureApplied:(UIPinchGestureRecognizer *)sender
{
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
        {
            CGPoint location = [sender locationInView:sender.view];
            if (![_cropLayer hitTest:location]) {
                return;
            }
            pinchState = sender.state;
            initialLocation = [sender locationInView:sender.view];
            initialImageLayerFrame = _fitImageFrame;
            
            //Zoom in/out with respect to current crop center / imagelayer anchor
            imageLayerCurrentAnchorPosition = [self getCurrentImageLayerAnchorPoint];
            _lastFitImageFrame = _fitImageFrame;
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            CGPoint location = [sender locationInView:sender.view];
            if (![_cropLayer hitTest:location] || pinchState != UIGestureRecognizerStateBegan) {
                return;
            }
            imageLayerCurrentAnchorPosition = [self getCurrentImageLayerAnchorPoint];
            CGFloat newWidth = initialImageLayerFrame.size.width * sender.scale;
            CGFloat newHeight = initialImageLayerFrame.size.height * sender.scale;
            if (_lastFitImageFrame.size.width <= _lastFitImageFrame.size.height) {
                newHeight = newWidth * initialImageLayerFrame.size.height / initialImageLayerFrame.size.width;
            } else {
                newWidth = newHeight * initialImageLayerFrame.size.width / initialImageLayerFrame.size.height;
            }
            CGRect scaledFrame = CGRectMake(0, 0, newWidth, newHeight);
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            _imageLayer.bounds = scaledFrame;
            shapeLayer.bounds = scaledFrame;
            _fitImageFrame = scaledFrame;
            [self resetShapeLayerPath];
            [CATransaction commit];
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        {
            pinchState = sender.state;
            CGAffineTransform scaleTransform = [self getScaleTransform];
            CGPoint poinstArray[] = {imageBottomLeftPoint, imageTopLeftPoint, imageTopRightPoint, imageBottomRightPoint};
            CGRect smallestRect = CGRectSmallestWithCGPoints(poinstArray, 4);
            smallestRect = CGRectIntegral(CGRectApplyAffineTransform(smallestRect, scaleTransform));
            smallestRect = CGRectApplyAffineTransform(smallestRect, _imageLayer.affineTransform);
            UIBezierPath *tempBezierPath = [UIBezierPath bezierPathWithCGPath:bezierPathForShapeLayer.CGPath];
            [tempBezierPath applyTransform:scaleTransform];
            CGRect boundingBox = CGPathGetBoundingBox(tempBezierPath.CGPath);
            boundingBox = CGRectApplyAffineTransform(boundingBox, _imageLayer.affineTransform);
            CGFloat widthDiff = (boundingBox.size.width - smallestRect.size.width) / 2.0;
            CGFloat heightDiff = (boundingBox.size.height - smallestRect.size.height) / 2.0;
            smallestRect = [shapeLayer convertRect:smallestRect toLayer:self.layer];
            widthDiff = 0;
            heightDiff = 0;
            CGPoint topLeft = [self converPointFromLayertoImage:imageTopLeftPoint];
            CGPoint topRight = [self converPointFromLayertoImage:imageTopRightPoint];
            CGPoint bottomLeft = [self converPointFromLayertoImage:imageBottomLeftPoint];
            CGPoint bottomRight = [self converPointFromLayertoImage:imageBottomRightPoint];
            
            bool topLeftIntersects = LineIntersectsRect(topLeft, topRight, _cropLayer.frame);
            bool topRightIntersects = LineIntersectsRect(topRight, bottomRight, _cropLayer.frame);
            bool bottomLeftIntersects = LineIntersectsRect(bottomRight, bottomLeft, _cropLayer.frame);
            bool bottomRightIntersects = LineIntersectsRect(bottomLeft, topLeft, _cropLayer.frame);
            
            if(topLeftIntersects || topRightIntersects || bottomRightIntersects || bottomLeftIntersects)
            {
                CGPoint center = _cropLayer.position;
                if((topRightIntersects && bottomRightIntersects) || (topLeftIntersects && bottomLeftIntersects))
                {
                    CGFloat width = fabs(cos(rotationAngle)) * (_cropLayer.frame.size.width + widthDiff) + fabs(sin(rotationAngle)) * (_cropLayer.frame.size.height) + heightDiff;
                    CGFloat height = fabs(sin(rotationAngle)) * (_cropLayer.frame.size.width + widthDiff) + fabs(cos(rotationAngle)) * (_cropLayer.frame.size.height) + heightDiff;
                    if(_inputImage.size.width > _inputImage.size.height)
                        width = _inputImage.size.width / _inputImage.size.height * height;
                    else
                        height = _inputImage.size.height / _inputImage.size.width * width;
                    
                    [CATransaction begin];
                    [CATransaction setDisableActions:NO];
                    CGRect newBounds = CGRectMake(0, 0, width, height);
                    _imageLayer.frame = newBounds;
                    shapeLayer.frame = newBounds;
                    _fitImageFrame = newBounds;
                    [self resetShapeLayerPath];
                    [CATransaction commit];
                }

                [CATransaction begin];
                [CATransaction setDisableActions:NO];
                _imageLayer.position = center;
                shapeLayer.position = center;
                [self resetShapeLayerPath];
                [CATransaction commit];
            }

            zoomScale = sender.scale;
            sender.scale = 1.0;
            _lastFitImageFrame = _fitImageFrame;
            break;
        }
        case UIGestureRecognizerStateFailed:
        {
            NSLog(@"UIGestureRecognizerStateFailed");
            break;
        }
            
        default:
            break;
    }
}

bool LineIntersectsLine(CGPoint l1p1, CGPoint l1p2, CGPoint l2p1, CGPoint l2p2)
{
    CGFloat q = (l1p1.y - l2p1.y) * (l2p2.x - l2p1.x) - (l1p1.x - l2p1.x) * (l2p2.y - l2p1.y);
    CGFloat d = (l1p2.x - l1p1.x) * (l2p2.y - l2p1.y) - (l1p2.y - l1p1.y) * (l2p2.x - l2p1.x);

    if( d == 0 )
    {
        return false;
    }

    float r = q / d;

    q = (l1p1.y - l2p1.y) * (l1p2.x - l1p1.x) - (l1p1.x - l2p1.x) * (l1p2.y - l1p1.y);
    float s = q / d;

    if( r < 0 || r > 1 || s < 0 || s > 1 )
    {
        return false;
    }

    return true;
}

bool LineIntersectsRect(CGPoint p1, CGPoint p2, CGRect r)
{
    CGPoint topLeftPoint = r.origin;
    CGPoint topRightPoint = CGPointMake(CGRectGetMaxX(r), r.origin.y);
    CGPoint bottomRightPoint = CGPointMake(CGRectGetMaxX(r), CGRectGetMaxY(r));
    CGPoint bottomLeftPoint = CGPointMake(r.origin.x, CGRectGetMaxY(r));
    
    return LineIntersectsLine(p1, p2, topLeftPoint, topRightPoint) ||
    LineIntersectsLine(p1, p2, topRightPoint, bottomRightPoint) ||
    LineIntersectsLine(p1, p2, bottomRightPoint, bottomLeftPoint) ||
    LineIntersectsLine(p1, p2, bottomLeftPoint, topLeftPoint) ||
    (CGRectContainsPoint(r, p1) && CGRectContainsPoint(r, p2));
}

- (CGPoint)getCurrentImageLayerAnchorPoint {
    
    CGPoint cropLayerCenter = CGPointMake(CGRectGetMidX(_cropLayer.frame), CGRectGetMidY(_cropLayer.frame));
    return CGPointMake(cropLayerCenter.x / _imageLayer.frame.size.width, cropLayerCenter.y / _imageLayer.frame.size.height);
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
    CGRect newCropFrame = CGRectIntegral(AVMakeRectWithAspectRatioInsideRect(previousCropLayerFrame.size, CGRectMake(kMinimumCropAreaInset, kMinimumCropAreaInset, (self.bounds.size.width - (kMinimumCropAreaInset * 2.0)), (self.bounds.size.height - (kMinimumCropAreaInset * 2.0)))));
    
    CGFloat scale = MIN(newCropFrame.size.width / previousCropLayerFrame.size.width, newCropFrame.size.height / previousCropLayerFrame.size.height);
    
    //Zoom in/out with respect to current crop center
    CGPoint cropLayerCenter = CGPointMake(CGRectGetMidX(previousCropLayerFrame), CGRectGetMidY(previousCropLayerFrame));
    
    imageLayerCurrentAnchorPosition = CGPointMake(cropLayerCenter.x / _imageLayer.frame.size.width, cropLayerCenter.y / _imageLayer.frame.size.height);
    
    CGRect scaledImageLayerFrame = [self calculateImageLayerScaledFrame:_imageLayer.frame scale:scale anchorPoint:imageLayerCurrentAnchorPosition];
    
    //Move it to center relative to previous crop frame
    CGPoint scaledImageLayerZoomCenter = CGPointMake(imageLayerCurrentAnchorPosition.x * scaledImageLayerFrame.size.width, imageLayerCurrentAnchorPosition.y * scaledImageLayerFrame.size.height);
    CGPoint imageLayerContainerLayerCenter = _imageLayer.position;
    CGFloat centerXoffset = scaledImageLayerZoomCenter.x - CGRectGetMidX(scaledImageLayerFrame);
    CGFloat centerYoffset = scaledImageLayerZoomCenter.y - CGRectGetMidY(scaledImageLayerFrame);
    
    CGPoint currentPosition = CGPointMake(imageLayerContainerLayerCenter.x - centerXoffset, imageLayerContainerLayerCenter.y - centerYoffset);
    _imageLayer.bounds = scaledImageLayerFrame;
    shapeLayer.bounds = _imageLayer.bounds;
    _imageLayer.position = currentPosition;
    shapeLayer.position = _imageLayer.position;
    _fitImageFrame = scaledImageLayerFrame;
    _cropLayer.frame = newCropFrame;
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
    
    CGFloat radian = angle * M_PI / 180.0;
    CGFloat deltaAngle = radian - CGAffineTransformGetAngle(_imageLayer.affineTransform);
    CGAffineTransform rotateTransform = CGAffineTransformRotate(_imageLayer.affineTransform, deltaAngle);
    CGPoint center = _cropLayer.position;
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    _imageLayer.anchorPoint = imageLayerCurrentAnchorPosition;
    shapeLayer.anchorPoint = imageLayerCurrentAnchorPosition;
    _imageLayer.affineTransform = rotateTransform;
    shapeLayer.affineTransform = rotateTransform;
    _imageLayer.anchorPoint = CGPointMake(0.5, 0.5);
    shapeLayer.anchorPoint = CGPointMake(0.5, 0.5);
    [self resetShapeLayerPath];
    [CATransaction commit];

    rotationAngle = radian;

    if([self IsIntersectedCropLayer:CGPointZero isCropResizing:NO])
    {
        // position scroll view
        CGAffineTransform scaleTransform = [self getScaleTransform];
        UIBezierPath *tempBezierPath = [UIBezierPath bezierPathWithCGPath:bezierPathForShapeLayer.CGPath];
        [tempBezierPath applyTransform:scaleTransform];
        CGRect boundingBox = CGPathGetBoundingBox(tempBezierPath.CGPath);
        
        
        CGRect fittedImageRect = CGRectIntegral(AVMakeRectWithAspectRatioInsideRect(_inputImage.size, _cropLayer.bounds));
        CGFloat scaleX = fittedImageRect.size.width / _inputImage.size.width;
        CGFloat scaleY = fittedImageRect.size.height / _inputImage.size.height;
        CGAffineTransform scale = CGAffineTransformMakeScale(scaleX, scaleY);
        CGFloat widthDiff = _imageLayer.frame.size.width - boundingBox.size.width;
        CGFloat heightDiff = _imageLayer.frame.size.height - boundingBox.size.height;
        
        widthDiff = (MAX(imageBottomRightPoint.x, imageTopRightPoint.x) - _inputImage.size.width) * 2;
        heightDiff = (MAX(imageTopLeftPoint.y, imageTopRightPoint.y) - _inputImage.size.height) * 2;
        
        CGSize sizeDiff = CGSizeMake(widthDiff, heightDiff);
        sizeDiff = CGSizeApplyAffineTransform(sizeDiff, scale);
        sizeDiff = CGSizeZero;
        CGFloat width = fabs(cos(rotationAngle)) * (_cropLayer.frame.size.width + sizeDiff.width) + fabs(sin(rotationAngle)) * (_cropLayer.frame.size.height + sizeDiff.height);
        CGFloat height = fabs(sin(rotationAngle)) * (_cropLayer.frame.size.width + sizeDiff.width) + fabs(cos(rotationAngle)) * (_cropLayer.frame.size.height + sizeDiff.height);
        if(_inputImage.size.width > _inputImage.size.height)
            width = _inputImage.size.width / _inputImage.size.height * height;
        else
            height = _inputImage.size.height / _inputImage.size.width * width;


        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        CGRect newBounds = CGRectMake(0, 0, width, height);
        _imageLayer.bounds = newBounds;
        shapeLayer.bounds = newBounds;
        _imageLayer.position = center;
        shapeLayer.position = center;
        _fitImageFrame = newBounds;
        [self resetShapeLayerPath];
        [CATransaction commit];
    }

//    [CATransaction begin];
//    [CATransaction setDisableActions:YES];
//    _imageLayer.anchorPoint = imageLayerCurrentAnchorPosition;
//    shapeLayer.anchorPoint = imageLayerCurrentAnchorPosition;
//    _imageLayer.affineTransform = rotateTransform;
//    shapeLayer.affineTransform = rotateTransform;
//    _imageLayer.anchorPoint = CGPointMake(0.5, 0.5);
//    shapeLayer.anchorPoint = CGPointMake(0.5, 0.5);
//    if([self IsIntersectedCropLayer:CGPointZero])
//        [self resizeImageLayerOnDemand];
//    [CATransaction commit];

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
        
//        CGPoint poinstArray[] = {imageBottomLeftPoint, imageTopLeftPoint, imageTopRightPoint, imageBottomRightPoint};
//        CGRect smallestRect = CGRectSmallestWithCGPoints(poinstArray, 4);
//        smallestRect = CGRectApplyAffineTransform(smallestRect, scaleTransform);
        CGRect boundingBox = CGPathGetBoundingBox(shapeLayer.path);
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        shapeLayer.bounds = boundingBox;
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
    rect.size.width = greatestXValue - fabs(smallestXValue);
    rect.size.height = greatestYValue - fabs(smallestYValue);

    return rect;
}

- (void)skewImageLayerHorizontally:(CGFloat)skewAngle shouldReset:(BOOL)reset {
//    if (skewAngle >50.0f || skewAngle < -50.0f) {
//        return;
//    }
    skewAngleH = skewAngle / 10.0;
    skewHorizontalValue = skewAngle;
    CGFloat value = skewAngle;
    value = value / 200 * _inputImage.size.height;
    if(reset)
    {
        if(flippedHorizontally)
        {
            if (value>=0) {
                imageTopLeftPoint.y = _inputImage.size.height;
                imageBottomLeftPoint.y = 0;
            }else{
                imageTopRightPoint.y = _inputImage.size.height;
                imageBottomRightPoint.y = 0;
            }
        }
        else
        {
            if (value>=0) {
                imageTopLeftPoint.y = _inputImage.size.height;
                imageBottomLeftPoint.y = 0;
            }else{
                imageTopRightPoint.y = _inputImage.size.height;
                imageBottomRightPoint.y = 0;
            }
        }
    }
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

- (void)skewImageLayerVertically:(CGFloat)skewAngle shouldReset:(BOOL)reset {
//    if (skewAngle >50.0f || skewAngle < -50.0f) {
//        return;
//    }
    skewAngleV = skewAngle / 10.0;
    skewVerticalValue = skewAngle;
    CGFloat value = skewAngle;
    value = value / 200 * _inputImage.size.width;
    if(reset)
    {
        if(flippedVertically)
        {
            if (value< 0) {
                imageBottomLeftPoint.x = 0;
                imageBottomRightPoint.x = _inputImage.size.width;
            }else{
                imageTopLeftPoint.x = 0;
                imageTopRightPoint.x = _inputImage.size.width;
            }
        }
        else
        {
            if (value>= 0) {
                imageTopLeftPoint.x = 0;
                imageTopRightPoint.x = _inputImage.size.width;
            }else{
                imageBottomLeftPoint.x = 0;
                imageBottomRightPoint.x = _inputImage.size.width;
            }

        }
    }
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
        
        if (possibleCropLayerWidth < initialCropLayerFrame.size.width || possibleCropLayerHeight < initialCropLayerFrame.size.height){
            return NO;
        }
        
        cropFrame.origin = possibleCropLayerOrigin;
        cropFrame.size = CGSizeMake(possibleCropLayerWidth, possibleCropLayerHeight);
    }
    
    CGPoint tl = CGPointMake(cropFrame.origin.x + 1, cropFrame.origin.y + 1);
    [cropPoints addObject:[NSValue valueWithCGPoint:tl]];
    CGPoint tr = CGPointMake(cropFrame.origin.x + cropFrame.size.width - 1, cropFrame.origin.y + 1);
    [cropPoints addObject:[NSValue valueWithCGPoint:tr]];
    CGPoint br = CGPointMake(cropFrame.origin.x + cropFrame.size.width - 1, cropFrame.origin.y + cropFrame.size.height - 1);
    [cropPoints addObject:[NSValue valueWithCGPoint:br]];
    CGPoint bl = CGPointMake(cropFrame.origin.x + 1, cropFrame.origin.y + cropFrame.size.height - 1);
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
    
    if (!isCropResizing) {
    topLeft.x = topLeft.x + translation.x;
    topLeft.y = topLeft.y + translation.y;
    }
    [shapePoints addObject:[NSValue valueWithCGPoint:topLeft]];
    
    if (!isCropResizing) {
    topRight.x = topRight.x + translation.x;
    topRight.y = topRight.y + translation.y;
    }
    [shapePoints addObject:[NSValue valueWithCGPoint:topRight]];
    
    if (!isCropResizing) {
    bottomRight.x = bottomRight.x + translation.x;
    bottomRight.y = bottomRight.y + translation.y;
    }
    [shapePoints addObject:[NSValue valueWithCGPoint:bottomRight]];
    
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
    convertedPoint = [shapeLayer convertPoint:convertedPoint toLayer:self.layer];
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
}

-(void)flipImageVertical{
    flippedVertically = !flippedVertically;
}

#pragma mark Done Btn Action

-(UIImage *)saveModelAndApply{
    [self saveDataModel];
    UIImage *outputImage = [cropDataModel croppedImage:_inputImage];
    NSLog(@"outputImage size %@",NSStringFromCGSize(outputImage.size));
    return outputImage;
}

#pragma mark Save Model

-(void)saveDataModel{
    
    cropDataModel.imageBottomLeftPoint = imageBottomLeftPoint;
    cropDataModel.imageTopLeftPoint = imageTopLeftPoint;
    cropDataModel.imageTopRightPoint = imageTopRightPoint;
    cropDataModel.imageBottomRightPoint = imageBottomRightPoint;
    cropDataModel.imageTranslationPoint = [self photoTranslation];
    cropDataModel.flipH = flippedHorizontally;
    cropDataModel.flipV = flippedVertically;
    cropDataModel.cropSize = _cropLayer.bounds.size;
    cropDataModel.imageLayerSize = _imageLayer.bounds.size;
    cropDataModel.rotationAngle = CGAffineTransformGetAngle(_imageLayer.affineTransform);
    cropDataModel.zoomScale = zoomScale;

}

- (CGPoint)photoTranslation
{
    CGPoint point = _imageLayer.position; //CGPointMake(rect.origin.x + rect.size.width / 2, rect.origin.y + rect.size.height / 2);
    CGPoint zeroPoint = initialImageLayerPosition;
    return CGPointMake(point.x - zeroPoint.x, point.y - zeroPoint.y);
}



@end
