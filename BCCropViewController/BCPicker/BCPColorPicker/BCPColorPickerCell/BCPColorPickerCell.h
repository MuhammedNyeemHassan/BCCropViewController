//
//  BCPColorPickerCell.h
//  BCPicker
//
//  Created by Somoy Das Gupta on 4/2/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BCPColorPickerCell : UICollectionViewCell
@property (nonatomic, copy) UIColor *cellColor;
@property (nonatomic, copy) NSArray<UIColor*> * gradientColorArray;
@end

NS_ASSUME_NONNULL_END
