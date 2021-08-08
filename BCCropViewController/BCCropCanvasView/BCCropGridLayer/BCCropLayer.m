//
//  BCCropLayer.m
//  BCCropViewController
//
//  Created by Somoy Das Gupta on 4/8/21.
//

#import "BCCropLayer.h"
#import <UIKit/UIKit.h>

#define CROP_LINE_COLOR [UIColor colorWithWhite:1.0 alpha:1.0]
#define GRID_LINE_COLOR [UIColor colorWithRed:0.52 green:0.48 blue:0.47 alpha:0.8]

const CGFloat kMaxRotationAngle = 0.5;
static const NSUInteger kCropLines = 2;
static const NSUInteger kGridLines = 10;

static const CGFloat kCropViewHotArea = 60;
static const CGFloat kCropViewCoolArea = 16;
static const CGFloat kMaximumCanvasWidthRatio = 1.0;
static const CGFloat kMaximumCanvasHeightRatio = 1.0;
static const CGFloat kCanvasHeaderHeigth = 0;
static const CGFloat kCropViewCornerLength = 50;

@interface BCCropCornerLayer : CALayer

@property (nonatomic) BCCropCornerType type;

@end

@implementation BCCropCornerLayer

- (instancetype)initWithCornerType:(BCCropCornerType)type
{
    if (self = [super init]) {
        self.frame = CGRectMake(0, 0, kCropViewCornerLength, kCropViewCornerLength);
        self.backgroundColor = UIColor.clearColor.CGColor;
        
        CGFloat lineWidth = 2.0;
        CALayer *horizontal = [[CALayer alloc] init];
        horizontal.frame = CGRectMake(0, 0, (kCropViewCornerLength / 2.0) + lineWidth, lineWidth);
        horizontal.backgroundColor = CROP_LINE_COLOR.CGColor;
        [self addSublayer:horizontal];
        
        CALayer *vertical = [[CALayer alloc] init];
        vertical.frame = CGRectMake(0, 0, lineWidth, (kCropViewCornerLength / 2.0) + lineWidth);
        vertical.backgroundColor = CROP_LINE_COLOR.CGColor;
        [self addSublayer:vertical];
        
        _type = type;
        
        if (_type == BCCropCornerTypeUpperLeft) {
            horizontal.position = CGPointMake(((3.0 * kCropViewCornerLength) / 4.0) - (lineWidth / 2.0), (kCropViewCornerLength / 2.0) - (lineWidth / 2.0));
            vertical.position = CGPointMake((kCropViewCornerLength / 2.0) - (lineWidth / 2.0), ((3.0 * kCropViewCornerLength) / 4.0) - (lineWidth / 2.0));
        }
        else if (_type == BCCropCornerTypeUpperRight) {
            horizontal.position = CGPointMake((kCropViewCornerLength / 4.0) + (lineWidth / 2.0), (kCropViewCornerLength / 2.0) - (lineWidth / 2.0));
            vertical.position = CGPointMake((kCropViewCornerLength / 2.0) + (lineWidth / 2.0), ((3.0 * kCropViewCornerLength) / 4.0) - (lineWidth / 2.0));
        }
        else if (_type == BCCropCornerTypeLowerLeft) {
            horizontal.position = CGPointMake(((3.0 * kCropViewCornerLength) / 4.0) - (lineWidth / 2.0), (kCropViewCornerLength / 2.0) + (lineWidth / 2.0));
            vertical.position = CGPointMake((kCropViewCornerLength / 2.0) - (lineWidth / 2.0), (kCropViewCornerLength / 4.0) + (lineWidth / 2.0));
        }
        else if (_type == BCCropCornerTypeLowerRight) {
            horizontal.position = CGPointMake((kCropViewCornerLength / 4.0) + (lineWidth / 2.0), (kCropViewCornerLength / 2.0) + (lineWidth / 2.0));
            vertical.position = CGPointMake((kCropViewCornerLength / 2.0) + (lineWidth / 2.0), (kCropViewCornerLength / 4.0) + (lineWidth / 2.0));
        }
    }
    return self;
}

@end

@interface BCCropLayer()

@property (nonatomic, strong) BCCropCornerLayer *upperLeft;
@property (nonatomic, strong) BCCropCornerLayer *upperRight;
@property (nonatomic, strong) BCCropCornerLayer *lowerRight;
@property (nonatomic, strong) BCCropCornerLayer *lowerLeft;

@property (nonatomic, strong) NSMutableArray *horizontalCropLines;
@property (nonatomic, strong) NSMutableArray *verticalCropLines;

@property (nonatomic, strong) NSMutableArray *horizontalGridLines;
@property (nonatomic, strong) NSMutableArray *verticalGridLines;

@property (nonatomic, assign) BOOL showCropLines;
@property (nonatomic, assign) BOOL showGridLines;

@property float cropWidthLimit;
@property float cropHeightLimit;

@property (nonatomic) BOOL shouldAnimateResizing;
@end

@implementation BCCropLayer

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    
    self.backgroundColor = UIColor.clearColor.CGColor;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [[BCCropLayer alloc] init]) {
        
        self.frame = frame;
        
        _cropWidthLimit = frame.size.width + 5;
        _cropHeightLimit = frame.size.height + 5;
        
        [self prepareCornerLayers];
        [self prepareLineLayers];
    }
    
    return self;
}

- (BOOL)needsDisplayOnBoundsChange {
    return YES;
}

- (void)layoutSublayers {
    [super layoutSublayers];
    
    [self resetCornerLayerPositions];
    [self resetCropLineFrames];
    [self resetGridLineFrames];
}

//MARK:- Corner Layers
- (void)prepareCornerLayers {
    
    _upperLeft = [[BCCropCornerLayer alloc] initWithCornerType:BCCropCornerTypeUpperLeft];
    _upperLeft.position = CGPointMake(kCropViewCornerLength / 2, kCropViewCornerLength / 2);
    [self addSublayer:_upperLeft];
    
    _upperRight = [[BCCropCornerLayer alloc] initWithCornerType:BCCropCornerTypeUpperRight];
    _upperRight.position = CGPointMake(self.frame.size.width - kCropViewCornerLength / 2, kCropViewCornerLength / 2);
    [self addSublayer:_upperRight];
    
    _lowerRight = [[BCCropCornerLayer alloc] initWithCornerType:BCCropCornerTypeLowerRight];
    _lowerRight.position = CGPointMake(self.frame.size.width - kCropViewCornerLength / 2, self.frame.size.height - kCropViewCornerLength / 2);
    [self addSublayer:_lowerRight];
    
    _lowerLeft = [[BCCropCornerLayer alloc] initWithCornerType:BCCropCornerTypeLowerLeft];
    _lowerLeft.position = CGPointMake(kCropViewCornerLength / 2, self.frame.size.height - kCropViewCornerLength / 2);
    [self addSublayer:_lowerLeft];
}

- (void)resetCornerLayerPositions {
    _upperLeft.position = CGPointMake(0, 0);
    _upperRight.position = CGPointMake(self.frame.size.width, 0);
    _lowerRight.position = CGPointMake(self.frame.size.width, self.frame.size.height);
    _lowerLeft.position = CGPointMake(0, self.frame.size.height);
}

//MARK:- Prepare Line Layers
- (void)prepareLineLayers {
    
    _horizontalGridLines = [NSMutableArray array];
    for (int i = 0; i < kGridLines; i++) {
        CALayer *line = [CALayer layer];
        line.backgroundColor = GRID_LINE_COLOR.CGColor;
        [_horizontalGridLines addObject:line];
        [self addSublayer:line];
    }

    _verticalGridLines = [NSMutableArray array];
    for (int i = 0; i < kGridLines; i++) {
        CALayer *line = [CALayer layer];
        line.backgroundColor = GRID_LINE_COLOR.CGColor;
        [_verticalGridLines addObject:line];
        [self addSublayer:line];
    }
    
    _horizontalCropLines = [NSMutableArray array];
    for (int i = 0; i < kCropLines; i++) {
        CALayer *line = [CALayer layer];
        line.backgroundColor = CROP_LINE_COLOR.CGColor;
        [_horizontalCropLines addObject:line];
        [self addSublayer:line];
    }

    _verticalCropLines = [NSMutableArray array];
    for (int i = 0; i < kCropLines; i++) {
        CALayer *line = [CALayer layer];
        line.backgroundColor = CROP_LINE_COLOR.CGColor;
        [_verticalCropLines addObject:line];
        [self addSublayer:line];
    }
}

//MARK:- Update line layer frames
- (void)resetCropLineFrames {
    
//    //Show crop lines
//    if (self.cropLinesHidden) {
//        [self showCropLines];
//    }
    
    if (!_shouldAnimateResizing) {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
    }
    
    [self updateCropLineFrames:self.horizontalCropLines horizontal:YES];
    [self updateCropLineFrames:self.verticalCropLines horizontal:NO];
    
    if (!_shouldAnimateResizing) {
        [CATransaction commit];
    }
}

- (void)resetGridLineFrames {
    
    if (!_shouldAnimateResizing) {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
    }
    
    [self updateGridLineFrames:self.horizontalGridLines horizontal:YES];
    [self updateGridLineFrames:self.verticalGridLines horizontal:NO];
    
    if (!_shouldAnimateResizing) {
        [CATransaction commit];
    }
}

- (void)updateCropLineFrames:(NSArray *)lines horizontal:(BOOL)horizontal {
    
    [lines enumerateObjectsUsingBlock:^(CALayer *line, NSUInteger idx, BOOL *stop) {
        
        if (horizontal) {
            line.frame = CGRectMake(0, ((self.frame.size.height / (lines.count + 1)) * (idx + 1)) - 0.5, self.frame.size.width, 1.0);
        }
        else {
            line.frame = CGRectMake(((self.frame.size.width / (lines.count + 1)) * (idx + 1)) - 0.5, 0, 1.0, self.frame.size.height);
        }
    }];
}

- (void)updateGridLineFrames:(NSArray *)lines horizontal:(BOOL)horizontal {
    
    [lines enumerateObjectsUsingBlock:^(CALayer *line, NSUInteger idx, BOOL *stop) {
        
        CGFloat sideLength = 1.0 / [UIScreen mainScreen].scale;
        
        CGFloat offset = 0;
        if (idx > 0 && idx < lines.count - 1) {
            offset = sideLength / 2.0;
        }
        else if (idx == lines.count - 1) {
            offset = sideLength;
        }
            
        if (horizontal) {
            line.frame = CGRectMake(0, ((self.frame.size.height / (lines.count - 1)) * idx) - offset, self.frame.size.width, sideLength);
        }
        else {
            line.frame = CGRectMake(((self.frame.size.width / (lines.count - 1)) * idx) - offset, 0, sideLength, self.frame.size.height);
        }
    }];
}

//MARK:- Show/Hide line layers
- (void)showCropLines:(BOOL)show {
    
    [self showLines:self.horizontalCropLines show:show];
    [self showLines:self.verticalCropLines show:show];
}

- (void)showGridLines:(BOOL)show {
    
    [self showLines:self.horizontalGridLines show:show];
    [self showLines:self.verticalGridLines show:show];
}

- (void)showLines:(NSArray *)lines show:(BOOL)show {
    [lines enumerateObjectsUsingBlock:^(CALayer *line, NSUInteger idx, BOOL *stop) {
        line.hidden = !show;
    }];
}

//MARK:- Public Methods
- (void)setShouldAnimateResizing:(BOOL)shouldAnimateResizing {
    _shouldAnimateResizing = shouldAnimateResizing;
}

- (void)setShowCropLines:(BOOL)showCropLines {
    _showCropLines = showCropLines;
    [self showCropLines:_showCropLines];
}

- (void)setShowGridLines:(BOOL)showGridLines {
    _showGridLines = showGridLines;
    [self showGridLines:_showGridLines];
}

- (BOOL)didTouchAnyCorner:(CGPoint)location {
    
    CGPoint convertedCropLayerPoint = [self.superlayer convertPoint:location toLayer:self];
    
    return [_upperLeft containsPoint:[self convertPoint:convertedCropLayerPoint toLayer:_upperLeft]] || [_upperRight containsPoint:[self convertPoint:convertedCropLayerPoint toLayer:_upperRight]] || [_lowerLeft containsPoint:[self convertPoint:convertedCropLayerPoint toLayer:_lowerLeft]] || [_lowerRight containsPoint:[self convertPoint:convertedCropLayerPoint toLayer:_lowerRight]];
}

- (BCCropCornerType)touchedCorner:(CGPoint)location {
    
    CGPoint convertedCropLayerPoint = [self.superlayer convertPoint:location toLayer:self];
    
    if ([_upperLeft containsPoint:[self convertPoint:convertedCropLayerPoint toLayer:_upperLeft]]) {
        return BCCropCornerTypeUpperLeft;
    }
    else if ([_upperRight containsPoint:[self convertPoint:convertedCropLayerPoint toLayer:_upperRight]]) {
        return BCCropCornerTypeUpperRight;
    }
    else if ([_lowerLeft containsPoint:[self convertPoint:convertedCropLayerPoint toLayer:_lowerLeft]]) {
        return BCCropCornerTypeLowerLeft;
    }
    else if ([_lowerRight containsPoint:[self convertPoint:convertedCropLayerPoint toLayer:_lowerRight]]) {
        return BCCropCornerTypeLowerRight;
    }
    else {
        return BCCropCornerTypeNone;
    }
}

@end
