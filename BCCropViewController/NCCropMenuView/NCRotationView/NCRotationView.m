//
//  NCRotationView.m
//  NoCrop
//
//  Created by Brain Craft Ltd. on 4/13/21.
//

#import "NCRotationView.h"

@implementation NCRotationView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

#pragma mark Actions

-(IBAction)rotateToLeftNinty:(id)sender{
    if ([self.delegate respondsToSelector:@selector(rotateToLeftNinty)]) {
        [self.delegate rotateToLeftNinty];
    }
}

-(IBAction)rotateToRightNinty:(id)sender{
    if ([self.delegate respondsToSelector:@selector(rotateToRightNinty)]) {
        [self.delegate rotateToRightNinty];
    }
}


@end
