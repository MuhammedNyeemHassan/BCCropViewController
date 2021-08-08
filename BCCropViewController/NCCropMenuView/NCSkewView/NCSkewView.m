//
//  NCSkewView.m
//  NoCrop
//
//  Created by Brain Craft Ltd. on 4/13/21.
//

#import "NCSkewView.h"

@interface NCSkewView(){
    IBOutlet UIButton *skew360btn;
    IBOutlet UIButton *skewHbtn;
    IBOutlet UIButton *skewVbtn;

}

@end
@implementation NCSkewView

-(void)awakeFromNib{
    [super awakeFromNib];
    [skewHbtn setSelected:YES];
}

-(void)deselectAllBtns{
    [skew360btn setSelected:NO];
    [skewHbtn setSelected:NO];
    [skewVbtn setSelected:NO];

}

#pragma mark Actions

-(IBAction)applyHorizontalSkew:(id)sender{
    [self deselectAllBtns];
    [skewHbtn setSelected:YES];
    if ([self.delegate respondsToSelector:@selector(applyHorizontalSkew)]) {
        [self.delegate applyHorizontalSkew];
    }
}

-(IBAction)applyVeticalSkew:(id)sender{
    [self deselectAllBtns];
    [skewVbtn setSelected:YES];
    if ([self.delegate respondsToSelector:@selector(applyVerticalSkew)]) {
        [self.delegate applyVerticalSkew];
    }
}

-(IBAction)apply360Skew:(id)sender{
    [self deselectAllBtns];
    [skew360btn setSelected:YES];
    if ([self.delegate respondsToSelector:@selector(apply360Skew)]) {
        [self.delegate apply360Skew];
    }
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
