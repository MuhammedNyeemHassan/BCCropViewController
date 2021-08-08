//
//  NCSkewView.h
//  NoCrop
//
//  Created by Brain Craft Ltd. on 4/13/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol NCSkewViewDelegate <NSObject>
-(void)applyHorizontalSkew;
-(void)applyVerticalSkew;
-(void)apply360Skew;
@end

@interface NCSkewView : UIView
@property (weak,nonatomic) id <NCSkewViewDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
