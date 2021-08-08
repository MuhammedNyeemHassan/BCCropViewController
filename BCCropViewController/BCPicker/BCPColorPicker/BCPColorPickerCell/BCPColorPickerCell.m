//
//  BCPColorPickerCell.m
//  BCPicker
//
//  Created by Somoy Das Gupta on 4/2/21.
//

#import "BCPColorPickerCell.h"

#define CELL_DEFAULT_CORNER_RADIUS (10.0 * ([[UIScreen mainScreen] bounds].size.width / 414.0))
#define CELL_DEFAULT_BORDER_WIDTH (2.0 * ([[UIScreen mainScreen] bounds].size.width / 414.0))
#define CELL_DEFAULT_BORDER_COLOR [UIColor colorWithRed:22.0/255.0f green:24.0/255.0f blue:26.0/255.0f alpha:1.0f]
#define CELL_DEFAULT_BORDER_LAYER_BG_COLOR [UIColor colorWithRed:38.0/255.0f green:209.0/255.0f blue:255.0/255.0f alpha:1.0f]

@interface BCPColorPickerCell () {
    CALayer *borderLayer;
    CAGradientLayer *gradientLayer;
}
@property (weak, nonatomic) IBOutlet UIImageView *gradientImageView;
@end

@implementation BCPColorPickerCell

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
    self.contentView.layer.cornerRadius = CELL_DEFAULT_CORNER_RADIUS;
    
    borderLayer = [[CALayer alloc] init];
    borderLayer.frame = CGRectMake(-CELL_DEFAULT_BORDER_WIDTH, -CELL_DEFAULT_BORDER_WIDTH, (self.bounds.size.width + (CELL_DEFAULT_BORDER_WIDTH * 2.0)), (self.bounds.size.height + (CELL_DEFAULT_BORDER_WIDTH * 2.0)));
    borderLayer.backgroundColor = CELL_DEFAULT_BORDER_LAYER_BG_COLOR.CGColor;
    borderLayer.cornerRadius = CELL_DEFAULT_CORNER_RADIUS + CELL_DEFAULT_BORDER_WIDTH;
    borderLayer.hidden = YES;
    [self.layer insertSublayer:borderLayer atIndex:0];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    borderLayer.frame = CGRectMake(-CELL_DEFAULT_BORDER_WIDTH, -CELL_DEFAULT_BORDER_WIDTH, (self.bounds.size.width + (CELL_DEFAULT_BORDER_WIDTH * 2.0)), (self.bounds.size.height + (CELL_DEFAULT_BORDER_WIDTH * 2.0)));
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    [gradientLayer removeFromSuperlayer];
    gradientLayer = nil;
}

//MARK:- Set Selected
- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    
    self.contentView.layer.borderColor = self.selected ? CELL_DEFAULT_BORDER_COLOR.CGColor : UIColor.clearColor.CGColor;
    self.contentView.layer.borderWidth = self.selected ? CELL_DEFAULT_BORDER_WIDTH : 0.0;
    borderLayer.hidden = !self.selected;
}

//MARK:- Color Setters
- (void)setCellColor:(UIColor *)cellColor {
    _cellColor = cellColor;
    _gradientImageView.backgroundColor = cellColor;
}

- (void)setGradientColorArray:(NSArray<UIColor*> *)gradientColorArray {
    _gradientColorArray = gradientColorArray;
    
    gradientLayer = [[CAGradientLayer alloc] init];
    gradientLayer.frame = _gradientImageView.bounds;
    gradientLayer.colors = _gradientColorArray;
    
//    CGFloat threshHold = ((pow(2.0, 1.0/2.0) - 1.0) / 2.0) / pow(2.0, 1.0/2.0);
    gradientLayer.locations = @[@0.16, @0.5];
    
    gradientLayer.startPoint = CGPointMake(0, 0);
    gradientLayer.endPoint = CGPointMake(0.5, 0.5);
    
    [_gradientImageView.layer addSublayer:gradientLayer];
}

@end
