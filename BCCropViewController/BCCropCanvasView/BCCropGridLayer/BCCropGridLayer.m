//
//  BCCropGridLayer.m
//  BCCropViewController
//
//  Created by Somoy Das Gupta on 4/8/21.
//

#import "BCCropGridLayer.h"
#import <UIKit/UIKit.h>

#define CROP_LINE_COLOR [UIColor colorWithWhite:1.0 alpha:1.0]

const CGFloat kMaxRotationAngle = 0.5;
static const NSUInteger kCropLines = 2;
static const NSUInteger kGridLines = 9;

static const CGFloat kCropViewHotArea = 60;
static const CGFloat kCropViewCoolArea = 16;
static const CGFloat kMinimumCropArea = 48;
static const CGFloat kMaximumCanvasWidthRatio = 1.0;
static const CGFloat kMaximumCanvasHeightRatio = 1.0;
static const CGFloat kCanvasHeaderHeigth = 0;
static const CGFloat kCropViewCornerLength = 22;

typedef NS_ENUM(NSInteger, BCCropCornerType) {
    CropCornerTypeUpperLeft,
    CropCornerTypeUpperRight,
    CropCornerTypeLowerRight,
    CropCornerTypeLowerLeft
};

@interface BCCropCornerLayer : CALayer

@property (nonatomic) BCCropCornerType type;

@end

@implementation BCCropCornerLayer

- (instancetype)initWithCornerType:(BCCropCornerType)type
{
    if (self = [super init]) {
        self.frame = CGRectMake(0, 0, kCropViewCornerLength, kCropViewCornerLength);
        self.backgroundColor = UIColor.clearColor.CGColor;
        
        CGFloat lineWidth = 2;
        CALayer *horizontal = [[CALayer alloc] init];
        horizontal.frame = CGRectMake(0, 0, kCropViewCornerLength, lineWidth);
        horizontal.backgroundColor = CROP_LINE_COLOR.CGColor;
        [self addSublayer:horizontal];
        
        CALayer *vertical = [[CALayer alloc] init];
        vertical.frame = CGRectMake(0, 0, lineWidth, kCropViewCornerLength);
        vertical.backgroundColor = CROP_LINE_COLOR.CGColor;
        [self addSublayer:vertical];
        
        _type = type;
        if (_type == CropCornerTypeUpperLeft) {
            horizontal.position = CGPointMake(kCropViewCornerLength / 2, lineWidth / 2);
            vertical.position = CGPointMake(lineWidth / 2, kCropViewCornerLength / 2);
        } else if (_type == CropCornerTypeUpperRight) {
            horizontal.position = CGPointMake(kCropViewCornerLength / 2, lineWidth / 2);
            vertical.position = CGPointMake(kCropViewCornerLength - lineWidth / 2, kCropViewCornerLength / 2);
        } else if (_type == CropCornerTypeLowerRight) {
            horizontal.position = CGPointMake(kCropViewCornerLength / 2, kCropViewCornerLength - lineWidth / 2);
            vertical.position = CGPointMake(kCropViewCornerLength - lineWidth / 2, kCropViewCornerLength / 2);
        } else if (_type == CropCornerTypeLowerLeft) {
            horizontal.position = CGPointMake(kCropViewCornerLength / 2, kCropViewCornerLength - lineWidth / 2);
            vertical.position = CGPointMake(lineWidth / 2, kCropViewCornerLength / 2);
        }
    }
    return self;
}

@end

@interface BCCropLayer()

@property (nonatomic, strong) CropCornerView *upperLeft;
@property (nonatomic, strong) CropCornerView *upperRight;
@property (nonatomic, strong) CropCornerView *lowerRight;
@property (nonatomic, strong) CropCornerView *lowerLeft;

@property (nonatomic, strong) NSMutableArray *horizontalCropLines;
@property (nonatomic, strong) NSMutableArray *verticalCropLines;

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

- (BOOL)needsDisplayOnBoundsChange {
    return YES;
}

- (void)layoutSublayers {
    [super layoutSublayers];
    
    
}

@end
