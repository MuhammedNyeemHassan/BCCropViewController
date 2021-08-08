//
//  BCPAllowAccessView.m
//  BCPicker
//
//  Created by Somoy Das Gupta on 3/2/21.
//

#import "BCPAllowAccessView.h"

#define ALLOW_ACCESS_IMAGEVIEW_LENGTH 60.0

#define ALLOW_ACCESS_TITLE_LABEL_FONT_SIZE 20.0
#define ALLOW_ACCESS_TITLE_LABEL_FONT_COLOR UIColor.whiteColor

#define ALLOW_ACCESS_DESCRIPTION_LABEL_WIDTH 285.0
#define ALLOW_ACCESS_DESCRIPTION_LABEL_FONT_SIZE 14.0
#define ALLOW_ACCESS_DESCRIPTION_LABEL_FONT_COLOR [UIColor colorWithRed:207.0/255.0f green:216.0/255.0f blue:230.0/255.0f alpha:1.0f]

#define ALLOW_ACCESS_PERMISSION_BUTTON_WIDTH 265.0
#define ALLOW_ACCESS_PERMISSION_BUTTON_HEIGHT 56.0
#define ALLOW_ACCESS_PERMISSION_BUTTON_FONT_SIZE 16.0
#define ALLOW_ACCESS_PERMISSION_BUTTON_FONT_COLOR UIColor.whiteColor

@interface BCPAllowAccessView()

@property (strong, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;


@end

@implementation BCPAllowAccessView

- (void)setDescriptionText:(NSString *)descriptionText {
    _descriptionText = descriptionText;
    _descriptionLabel.text = _descriptionText;
}

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
    self.backgroundColor = UIColor.clearColor;
    [[NSBundle mainBundle] loadNibNamed:@"BCPAllowAccessView" owner:self options:nil];
    
    [self addSubview:self.contentView];
    self.contentView.frame = self.bounds;
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.descriptionLabel.font = [UIFont fontWithName:@"SFProDisplay-Regular" size:14.0f];
}

- (void)prepareAllowAccessTitleLabel {
    
}

- (IBAction)allowAccessButtonPressed:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(allowAccessButtonPressed)]) {
        [self.delegate allowAccessButtonPressed];
    }
}


@end
