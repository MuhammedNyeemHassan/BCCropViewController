//
//  BCPAlbumTableViewCell.m
//  BCPicker
//
//  Created by Somoy Das Gupta on 8/4/21.
//

#import "BCPAlbumTableViewCell.h"

#define ALBUM_CELL_TITLE_FONT_SIZE (15.0 * ([[UIScreen mainScreen] bounds].size.width / 414.0))
#define ALBUM_CELL_TEXT_COLOR [UIColor colorWithRed:195.0/255.0f green:215.0/255.0f blue:230.0/255.0f alpha:1.0f]
#define ALBUM_CELL_IMAGE_CORNERRADIUS (4.0 * ([[UIScreen mainScreen] bounds].size.width / 414.0))

#define ALBUM_CELL_DEFAULT_BG_COLOR [UIColor clearColor]

@interface BCPAlbumTableViewCell ()
@property (weak, nonatomic) IBOutlet UIImageView *albumImageView;
@property (weak, nonatomic) IBOutlet UILabel *albumTitleLabel;

@end

@implementation BCPAlbumTableViewCell

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.backgroundColor = UIColor.clearColor;
    self.contentView.backgroundColor = ALBUM_CELL_DEFAULT_BG_COLOR;
    _albumImageView.layer.cornerRadius = ALBUM_CELL_IMAGE_CORNERRADIUS;
    _albumTitleLabel.textColor = ALBUM_CELL_TEXT_COLOR;
    _albumTitleLabel.font = [UIFont systemFontOfSize:ALBUM_CELL_TITLE_FONT_SIZE];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

//MARK:- Property Setter
- (void)setAlbum:(PHAssetCollection *)album {
    _album = album;
    _albumTitleLabel.text = _album.localizedTitle;
    
    PHFetchOptions *options = [PHFetchOptions new];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d", PHAssetMediaTypeImage];
    PHFetchResult<PHAsset*> *assets = [PHAsset fetchAssetsInAssetCollection:_album options:options];
    
    PHAsset *asset = assets.firstObject;
    
    if (asset) {
        PHImageRequestOptions *option = [PHImageRequestOptions new];
        option.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
        option.version = PHImageRequestOptionsVersionCurrent;
        option.resizeMode = PHImageRequestOptionsResizeModeExact;
        
        [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:CGSizeMake(UIScreen.mainScreen.scale * _albumImageView.bounds.size.width, UIScreen.mainScreen.scale * _albumImageView.bounds.size.height) contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self->_albumImageView.image = result;
            });
        }];
    }
}

- (void)setAlbumTitleFont:(UIFont *)albumTitleFont {
    _albumTitleFont = albumTitleFont;
    _albumTitleLabel.font = _albumTitleFont;
}

- (void)setAlbumTitleColor:(UIColor *)albumTitleColor {
    _albumTitleColor = albumTitleColor;
    _albumTitleLabel.textColor = _albumTitleColor;
}

@end
