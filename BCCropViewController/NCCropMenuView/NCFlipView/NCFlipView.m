//
//  NCFlipView.m
//  NoCrop
//
//  Created by Brain Craft Ltd. on 4/13/21.
//

#import "NCFlipView.h"

@interface  NCFlipView(){
}

@end

@implementation NCFlipView


#pragma mark Actions

- (void)deselctOptions {
    UIButton *flipHbtn =  (UIButton*)[self viewWithTag:2];
    UIButton *flipVbtn =  (UIButton*)[self viewWithTag:3];
    [flipHbtn setSelected:NO];
    [flipVbtn setSelected:NO];
}

-(IBAction)horizontalFlipPressed:(id)sender{
    UIButton *btn = (UIButton*)sender;
    [btn setSelected:!btn.selected];

    if ([self.delegate respondsToSelector:@selector(flipViewFlippedHorizontally)]) {
        [self.delegate flipViewFlippedHorizontally];
    }
}

-(IBAction)verticalFlipPressed:(id)sender{
    UIButton *btn = (UIButton*)sender;
    [btn setSelected:!btn.selected];

    if ([self.delegate respondsToSelector:@selector(flipViewFlippedVeritcally)]) {
        [self.delegate flipViewFlippedVeritcally];
    }
}

-(void)selectFlipHBtn{
    UIButton *flipHbtn =  (UIButton*)[self viewWithTag:2];
    [flipHbtn setSelected:YES];
}

-(void)selectFlipVBtn{
    UIButton *flipVbtn =  (UIButton*)[self viewWithTag:3];
    [flipVbtn setSelected:YES];
}

-(void)deSelectFlipHBtn{
    UIButton *flipHbtn =  (UIButton*)[self viewWithTag:2];
    [flipHbtn setSelected:NO];
}

-(void)deSelectFlipVBtn{
    UIButton *flipVbtn =  (UIButton*)[self viewWithTag:3];
    [flipVbtn setSelected:NO];
}



/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
