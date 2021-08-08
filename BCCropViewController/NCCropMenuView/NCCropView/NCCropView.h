//
//  NCCropView.h
//  NoCrop
//
//  Created by Brain Craft Ltd. on 4/13/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NCCropView;
@protocol NCCropViewDelegate <NSObject>
-(void)cropView:(NCCropView*)cropView didSelectRatio:(NSString*)ratio;
@end

@interface NCCropView : UIView
@property (weak,nonatomic) id <NCCropViewDelegate> delgate;
-(void)selectItemWithRatio:(NSString*)ratioStr;
@end

NS_ASSUME_NONNULL_END
