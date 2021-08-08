//
//  BCCropLayer.h
//  BCCropViewController
//
//  Created by Somoy Das Gupta on 4/8/21.
//

#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BCCropCornerType) {
    BCCropCornerTypeNone,
    BCCropCornerTypeUpperLeft,
    BCCropCornerTypeUpperRight,
    BCCropCornerTypeLowerLeft,
    BCCropCornerTypeLowerRight
};

@interface BCCropLayer : CALayer

- (instancetype)initWithFrame:(CGRect)frame;

- (void)setShouldAnimateResizing:(BOOL)shouldAnimateResizing;

- (void)setShowCropLines:(BOOL)showCropLines;
- (void)setShowGridLines:(BOOL)showGridLines;

- (BOOL)didTouchAnyCorner:(CGPoint)location;
- (BCCropCornerType)touchedCorner:(CGPoint)location;

@end

NS_ASSUME_NONNULL_END
