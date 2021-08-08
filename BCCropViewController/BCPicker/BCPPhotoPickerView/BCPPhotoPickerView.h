//
//  BCPPhotoPickerView.h
//  BCPicker
//
//  Created by Somoy Das Gupta on 28/1/21.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    BCPCamera,
    BCPPhoto,
    BCPFileManager
} BCPPhotoPickerViewAction;

typedef enum : NSUInteger {
    BCPPhotoCellView,
    BCPPhotoAlbumView
} BCPPhotoPickerAccessoryViewType;

@protocol BCPPhotoPickerViewDelegate <NSObject>

- (void)pickerCellPressed:(BCPPhotoPickerViewAction)action;
- (void)pickerDidSelectImage:(UIImage*)image;
- (void)askPermissionCamera:(void(^)(BOOL isPermitted))isPermitted;

@end

@interface BCPPhotoPickerView : UIView

@property (weak, nonatomic) id<BCPPhotoPickerViewDelegate> delegate;

/**
Photo Picker Accessory View type BCPPhotoPickerAccessoryViewType
 */
@property (nonatomic) BCPPhotoPickerAccessoryViewType accessoryViewType;

/**
 Load all albums from library
 */
- (void)loadAllAlbums;

/**
 Load all photos from library
 */
- (void)loadAllPhotos;

/**
 Load all selected photos from library - limited access
 */
- (void)loadAllSelectedPhotos;

/**
 Selected Album font
 */
@property (copy, nonatomic) UIFont *selectedAlbumFont;

/**
 Listed Album font
 */
@property (copy, nonatomic) UIFont *albumFont;
@end

NS_ASSUME_NONNULL_END
