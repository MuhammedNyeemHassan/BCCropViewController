//
//  ATPRotatesView.h
//  AddTextToPhoto
//
//  Created by Arsil Ajim on 19/3/19.
//  Copyright © 2019 Arsil. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NCCRRulerControl.h"
//#import "TextViewEditor.h"

@protocol AdjustRotateDelegate
-(void) setAdjustRotate:(CGFloat)rValues;
-(void) rotateAntiClockWise:(BOOL) flag;
-(void) rotateClockWise:(BOOL) flag;
-(void) update;
@end
NS_ASSUME_NONNULL_BEGIN

@interface NCRulerView : UIView {
    CGFloat rotateValue;
    NSTimer *timer;
}
@property (weak, nonatomic) id<AdjustRotateDelegate>delegate;
@property (nonatomic) CGFloat changedValue;
@property (nonatomic) BOOL isSkew;

@property (strong,nonatomic) NSString *angleText;

@property (nonatomic) int values;
@property (weak, nonatomic) IBOutlet NCCRRulerControl *rotateRulerView;
@property (weak, nonatomic) IBOutlet UIView *roundView;
@property (weak, nonatomic) IBOutlet UIView *circleView;

-(void) rulerSetup;
-(void) setInitialValues;
-(void) setLblText:(CGFloat)value withTag:(int)tag;
-(void)setRulerValue:(int)rulerValue;
- (IBAction)rulerAction:(id)sender;
- (IBAction)rulerValueChangeBtnAction:(UIButton *)sender;
- (IBAction)rotateRulerDragExitAction:(UIButton *)sender;
- (void)rotateContentNintyDegreesWithClockWise:(BOOL)clockWise;

@end

NS_ASSUME_NONNULL_END
