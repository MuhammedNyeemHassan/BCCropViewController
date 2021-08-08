//
//  BCPAlbumExpandingView.h
//  BCPicker
//
//  Created by Somoy Das Gupta on 8/4/21.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BCPAlbumExpandingViewDelegate <NSObject>

- (void)cameraButtonTapped;
- (void)expandAlbumView:(BOOL)expand;
- (void)didAlbumSelected:(NSUInteger)index;
- (void)reloadAllPhotos:(NSUInteger)albumIndex;

@end

@interface BCPAlbumExpandingView : UIView

@property (weak, nonatomic) id<BCPAlbumExpandingViewDelegate> delegate;

/**
 Album Array, Array of PHAssetCollections
 */
@property (strong, nonatomic) NSArray<PHAssetCollection*> *allAlbums;

/**
 Selected album index
 */
@property (nonatomic) NSUInteger selectedAlbumIndex;

/**
 Album Top View label font
 */
@property (copy, nonatomic) UIFont *selectedAlbumFont;

/**
 Album Top View label font color
 */
@property (copy, nonatomic) UIFont *selectedAlbumFontColor;

/**
 Album Tableview cell title font
 */
@property (copy, nonatomic) UIFont *albumFont;

/**
 Album Tableview cell title font color
 */
@property (copy, nonatomic) UIFont *albumFontColor;

@end

NS_ASSUME_NONNULL_END
