//
//  NCRotationView.h
//  NoCrop
//
//  Created by Brain Craft Ltd. on 4/13/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol NCRotationViewDelegate <NSObject>
-(void)rotateToLeftNinty;
-(void)rotateToRightNinty;
@end


@interface NCRotationView : UIView
@property (weak,nonatomic) id <NCRotationViewDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
