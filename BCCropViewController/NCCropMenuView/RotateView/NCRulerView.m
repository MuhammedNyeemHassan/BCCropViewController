//
//  ATPRotatesView.m
//  AddTextToPhoto
//
//  Created by Arsil Ajim on 19/3/19.
//  Copyright © 2019 Arsil. All rights reserved.
//

#import "NCRulerView.h"
#define ROTATE_RULER_MIN_VALUE -180
#define ROTATE_RULER_MAX_VALUE 180
#define SKEW_ROTATE_RULER_MIN_VALUE -50
#define SKEW_ROTATE_RULER_MAX_VALUE 50

@interface NCRulerView () <CRRulerControlDelegate>
{
    BOOL flag;
}

@end


@implementation NCRulerView

-(void)awakeFromNib{
    [super awakeFromNib];
    self.circleView.layer.cornerRadius = 16.5*RATIO;
    self.circleView.layer.borderColor = [UIColor colorWithHex:@"#373C40"].CGColor;

}

-(void)setIsSkew:(BOOL)isSkew{
    _isSkew = isSkew;
    if (self.isSkew) {
        self.rotateRulerView.rangeFrom = SKEW_ROTATE_RULER_MIN_VALUE;
        self.rotateRulerView.rangeLength = SKEW_ROTATE_RULER_MAX_VALUE - SKEW_ROTATE_RULER_MIN_VALUE;
        self.rotateRulerView.rulerWidth = (SKEW_ROTATE_RULER_MAX_VALUE - SKEW_ROTATE_RULER_MIN_VALUE) * 11;
    }else{
        self.rotateRulerView.rangeFrom = ROTATE_RULER_MIN_VALUE;
        self.rotateRulerView.rangeLength = ROTATE_RULER_MAX_VALUE - ROTATE_RULER_MIN_VALUE;
        self.rotateRulerView.rulerWidth = (ROTATE_RULER_MAX_VALUE - ROTATE_RULER_MIN_VALUE) * 11;
    }
}

-(void)setAngleText:(NSString *)angleText{
    _angleText = angleText;
    self.angelLabel.text = angleText;
}

-(void) rulerSetup {
    self.rotateRulerView.rangeFrom = ROTATE_RULER_MIN_VALUE;
    self.rotateRulerView.rangeLength = ROTATE_RULER_MAX_VALUE - ROTATE_RULER_MIN_VALUE;
    self.rotateRulerView.rulerWidth = (ROTATE_RULER_MAX_VALUE - ROTATE_RULER_MIN_VALUE) * 11;
    [self.rotateRulerView.pointerImageView removeFromSuperview];
    [self.rotateRulerView setFont:[UIFont systemFontOfSize:0] forMarkType:CRRulerMarkTypeAll];
    _rotateRulerView.delegate = self;
    
}

-(void) setRulerInitialValue {
    [self.rotateRulerView setValue:self.values animated:NO];
    [self setLblText:(int)self.rotateRulerView.value withTag:211];
}

-(void)setRulerValue:(int)rulerValue{
    self.angleText = [NSString stringWithFormat:@"%d",rulerValue];
    [self.rotateRulerView setValue:rulerValue animated:NO];
}

- (void)rotateContentNintyDegreesWithClockWise:(BOOL)clockWise {
    self.userInteractionEnabled = NO;
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      self.userInteractionEnabled = YES;
      });
    NCCRRulerControl *ruler =self.rotateRulerView;
    if (clockWise) {
        flag = NO;

        CGFloat currentValue = (ruler.value +90.0f);
        if(currentValue>180) {
            flag = YES;
            currentValue = (-currentValue +180);
            [ruler setValue:-180 animated:NO];
            self.changedValue = currentValue;
        }
        else
        {
            [ruler setValue:currentValue animated:YES];
        }
        [self reduceRotateValue];
        timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(reduceRotateValue) userInfo:nil repeats:NO];
    }
    else if (!clockWise) {
        flag = NO;
        CGFloat currentValue = ( ruler.value -90.0f);
        if(currentValue<-180) {
            flag = YES;
            currentValue = (-1*currentValue)-180;
            [ruler setValue:180 animated:NO];
            self.changedValue = currentValue;
        }
        else{
            [ruler setValue:currentValue animated:YES];
        }
        [self increaseRotateValue];
        
        timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(increaseRotateValue) userInfo:nil repeats:NO];
    }

    if (timer != nil) {
        [timer invalidate];
        timer = nil;
        return;
    }
}

- (IBAction)rulerAction:(id)sender {
    NCCRRulerControl *ruler = (NCCRRulerControl *)sender;
    if ([ruler isEqual:self.rotateRulerView]) {
        [self setLblText:ruler.value withTag:211];
    }
    [self setAdjustValues];
}

-(void) setLblText:(CGFloat)value withTag:(int)tag
{
//    NSLog(@"------------------------------------%f",value);
    UILabel *lbl = [self viewWithTag:tag];
    
    if(value>=0){
        value+=0.04;
        lbl.text = [NSString stringWithFormat:@"%d\u00b0", (int)ceilf(value)];
    }
    else{
        value-=.04;
        lbl.text = [NSString stringWithFormat:@"%d\u00b0",(int) floorf(value)];
    }
    
    if (tag == 211) {
        
//        CGFloat lowerThrashHold=-0.1500f;
//        CGFloat upperThrashHold=0.1500f;
//
//        CGFloat ceilValue = ceilf(value);
//        CGFloat floorValue = floorf(value);
//
//        if(
//
        
        
        rotateValue = value;
    }
}

-(void) setAdjustValues {
    [self.delegate setAdjustRotate:rotateValue];
}

-(void)setInitialValues {
    rotateValue = self.values;
    [self performSelector:@selector(setRulerInitialValue) withObject:nil afterDelay:0.0];
}

- (IBAction)rotateRulerDragExitAction:(UIButton *)sender {
    [self rulerValueChangeBtnAction:(UIButton *)sender];
}

-(void) reduceRotateValue {
    [self.delegate rotateClockWise:flag];
}

-(void)increaseRotateValue {
    [self.delegate rotateAntiClockWise:flag];
}

-(void) scrollEnded{
    [self.delegate update];
}

@end
