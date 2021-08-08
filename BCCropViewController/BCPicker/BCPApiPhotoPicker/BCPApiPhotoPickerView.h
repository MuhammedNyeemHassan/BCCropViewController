//
//  BCPUnsplashPickerView.h
//  BCPicker
//
//  Created by Somoy Das Gupta on 28/1/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    BCPUnsplashAPI,
    BCPPixabayAPI,
    BCPGooglePhotosAPI
} BCPApiPhotoPickerType;

@protocol BCPApiPhotoPickerViewDelegate <NSObject>

- (void)apiPhotoPickerDidPickImage:(UIImage*)image;

@end

@interface BCPApiPhotoPickerView : UIView

@property (nonatomic, weak) id<BCPApiPhotoPickerViewDelegate> delegate;

/**
 Set BCPApiPhotoPickerType type
 */
#if TARGET_INTERFACE_BUILDER
@property (nonatomic) IBInspectable NSUInteger type;
#else
@property (nonatomic) BCPApiPhotoPickerType type;
#endif

/**
 Set api key for BCPApiPhotoPickerType type
 */
@property (nonatomic, copy) NSString *apiKey;

/**
 Set BCPApiPhotoPickerType type
 */
@property (copy, nonatomic) UIColor *searchBarTintColor;
@property (copy, nonatomic) UIColor *searchBarBackgroundColor;

/**
 Search bar placeholder and text font
 */
@property (copy, nonatomic) UIFont *searchTextFont;

/**
 Photo cell title/name font
 */
@property (copy, nonatomic) UIFont *photoTitleFont;



@end

NS_ASSUME_NONNULL_END
