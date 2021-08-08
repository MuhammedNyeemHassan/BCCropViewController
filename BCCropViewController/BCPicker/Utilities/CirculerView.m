//
//  CirculerView.m
//  BCPicker
//
//  Created by Somoy Das Gupta on 12/2/18.
//  Copyright © 2018 Somoy Das Gupta. All rights reserved.
//

#import "CirculerView.h"

@implementation CirculerView

- (void)setBorderColor:(UIColor *)borderColor{
    _borderColor = borderColor;
    self.layer.borderColor = borderColor.CGColor;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

-(void)layoutSubviews {
    [super layoutSubviews];
}


#pragma mark - helper functions

-(void)setup
{
    self.contentMode=UIViewContentModeRedraw;
    self.clipsToBounds = YES;
    self.layer.cornerRadius = self.frame.size.height/2;
}


#pragma mark - drawing

-(void)drawRect:(CGRect)rect
{
    //call my supers
    [super drawRect:rect];
    
    [self setup];
}


@end
