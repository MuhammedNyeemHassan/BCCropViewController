//
//  BCPAlbumTopView.h
//  BCPicker
//
//  Created by Somoy Das Gupta on 8/4/21.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

#define ALBUM_EXPAND_NOTIFICATION @"Expand"

@protocol BCPAlbumTopViewDelegate <NSObject>

- (void)cameraButtonTapped;
- (void)expandAlbumView:(BOOL)expand;

@end

@interface BCPAlbumTopView : UIView

@property (weak, nonatomic) id<BCPAlbumTopViewDelegate> delegate;

@property (strong, nonatomic) PHAssetCollection *album;

@property (copy, nonatomic) UIFont *albumTitleFont;

@property (copy, nonatomic) UIColor *albumTitleColor;

@property (copy, nonatomic) UIColor *bgColor;

@end

NS_ASSUME_NONNULL_END
