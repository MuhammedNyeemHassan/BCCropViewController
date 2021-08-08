//
//  BCPAllowAccessView.h
//  BCPicker
//
//  Created by Somoy Das Gupta on 3/2/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BCPAllowAccessViewDelegate <NSObject>

- (void)allowAccessButtonPressed;

@end

@interface BCPAllowAccessView : UIView

@property (weak, nonatomic) id<BCPAllowAccessViewDelegate> delegate;
@property (copy, nonatomic) NSString *descriptionText;

@end

NS_ASSUME_NONNULL_END
