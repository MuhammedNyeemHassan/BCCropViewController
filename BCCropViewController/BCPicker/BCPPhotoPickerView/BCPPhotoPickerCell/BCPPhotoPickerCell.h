//
//  BCPPhotoPickerCell.h
//  BCPicker
//
//  Created by Somoy Das Gupta on 7/2/21.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface BCPPhotoPickerCell : UICollectionViewCell

@property (strong, nonatomic) PHAsset * _Nullable photoAsset;
@property (copy, nonatomic) NSString * _Nullable photoImageName;

@property (nonatomic) PHImageRequestID imageRequestID;

@end

NS_ASSUME_NONNULL_END
