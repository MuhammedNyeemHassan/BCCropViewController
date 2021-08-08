//
//  BCPApiPhotoPickerCell.h
//  BCPicker
//
//  Created by Somoy Das Gupta on 31/1/21.
//

#import <UIKit/UIKit.h>
#import "PBHit.h"
#import "USResult.h"

NS_ASSUME_NONNULL_BEGIN

@interface BCPApiPhotoPickerCell : UICollectionViewCell

@property (copy, nonatomic) UIFont *cellTitleFont;

- (void)configureWithHit:(PBHit *)hit;
- (void)configureWithResult:(USResult *)result;

@end
NS_ASSUME_NONNULL_END
