//
//  BCPAlbumTableViewCell.h
//  BCPicker
//
//  Created by Somoy Das Gupta on 8/4/21.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BCPAlbumTableViewCellDelegate <NSObject>

- (void)didAlbumSelected:(NSUInteger)index;

@end

@interface BCPAlbumTableViewCell : UITableViewCell

/**
 Cell album data
 */
@property (strong, nonatomic) PHAssetCollection *album;

@property (copy, nonatomic) UIFont *albumTitleFont;

@property (copy, nonatomic) UIColor *albumTitleColor;
@end

NS_ASSUME_NONNULL_END
