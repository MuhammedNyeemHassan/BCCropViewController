//
//  BCPicker.h
//  BCPicker
//
//  Created by Somoy Das Gupta on 28/1/21.
//

#import <UIKit/UIKit.h>
#import "BCPColorPickerView.h"
#import "BCPPhotoPickerView.h"

@class OIDAuthState;
@class OIDServiceConfiguration;

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, BCPickerOptions) {
    Photos       = 1 << 0,
    Colors       = 1 << 1,
    Unsplash     = 1 << 2,
    Pixabay      = 1 << 3,
    GooglePhotos = 1 << 4
};

@class BCPicker;

@protocol BCPickerControllerDelegate <NSObject>

@optional
- (void)bcPicker:(BCPicker*)picker didPickColor:(BCPColorType)type hexArray:(NSArray<NSString*>*)hexStrings;
- (void)bcPicker:(BCPicker*)picker didPickImage:(UIImage*)image;

@end

@interface BCPicker : UIViewController <UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) id<BCPickerControllerDelegate> delegate;

@property (nonatomic) BCPickerOptions pickerOptions;

@property (copy, nonatomic) UIColor * _Nullable themeColor;

/**
 BCPicker navigation bar title font
 */
@property (copy, nonatomic) UIFont * _Nullable navigationBarTitleFont;

//MARK:- BCMenuBarView Properties
/**
 BCMenuBarView menu font
 */
@property (copy, nonatomic) UIFont * _Nullable menuFont;

/**
 BCMenuBarView menu font
 */
@property (copy, nonatomic) UIFont * _Nullable menuSelectedFont;

//MARK:- Photo Picker Properties
/**
 Photo Picker Selected Album font
 */
@property (copy, nonatomic) UIFont *selectedAlbumFont;

/**
 Photo Picker Listed Album font
 */
@property (copy, nonatomic) UIFont *albumFont;

//MARK:- Color Picker Properties
@property (copy, nonatomic) UIFont * _Nullable colorSectionFont;
@property (copy, nonatomic) NSArray * colorGroupTitles;
@property (copy, nonatomic) NSArray<NSArray*>* colorPlistGroupArray;

//MARK:- Photo Picker Properties
/**
Photo Picker Accessory View type
 */
@property (nonatomic) BCPPhotoPickerAccessoryViewType photoPickerAccessoryViewType;

/**
 API Photo Picker search bar font
 */
@property (copy, nonatomic) UIFont * _Nullable apiSearchTextFont;

/**
 API Photo Picker title font
 */
@property (copy, nonatomic) UIFont * _Nullable apiPhotoTitleFont;

/**
 API Photo Picker Pixabay API Key
 */
@property (copy, nonatomic, nonnull) NSString *pixabayAPIKey;

/**
 API Photo Picker Unsplash API Key
 */
@property (copy, nonatomic, nonnull) NSString *unsplashAPIKey;


@end

NS_ASSUME_NONNULL_END
