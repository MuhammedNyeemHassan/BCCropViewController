//
//  NCFlipView.h
//  NoCrop
//
//  Created by Brain Craft Ltd. on 4/13/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol NCFlipViewDelegate <NSObject>
-(void)flipViewFlippedHorizontally;
-(void)flipViewFlippedVeritcally;
@end

@interface NCFlipView : UIView
@property (weak,nonatomic) id <NCFlipViewDelegate> delegate;
-(void)selectFlipHBtn;
-(void)selectFlipVBtn;
-(void)deSelectFlipHBtn;
-(void)deSelectFlipVBtn;
@end

NS_ASSUME_NONNULL_END
