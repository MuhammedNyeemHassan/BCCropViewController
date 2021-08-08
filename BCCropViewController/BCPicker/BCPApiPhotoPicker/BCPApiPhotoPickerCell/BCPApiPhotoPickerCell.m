//
//  BCPApiPhotoPickerCell.m
//  BCPicker
//
//  Created by Somoy Das Gupta on 31/1/21.
//

#import "BCPApiPhotoPickerCell.h"
#import "UIImageView+WebCache.h"

#define PHOTO_PICKER_CELL_FONT_SIZE 14.0

@interface BCPApiPhotoPickerCell()

@property (weak, nonatomic) IBOutlet UIImageView *cellImageView;
@property (weak, nonatomic) IBOutlet UILabel *cellLabel;

@end

@implementation BCPApiPhotoPickerCell

- (void)prepareForReuse {
    [super prepareForReuse];
    self.cellImageView.image = nil;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.layer.cornerRadius = 5.0f;
    self.cellImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.cellLabel.font = [UIFont systemFontOfSize:PHOTO_PICKER_CELL_FONT_SIZE];
}

- (void)configureWithHit:(PBHit *)hit
{
    [_cellImageView sd_setImageWithURL:[NSURL URLWithString: hit.previewURL]
                      placeholderImage:[UIImage imageNamed:@"pixabayPlaceholder"]];
    
    _cellLabel.text  = hit.user;
}

- (void)configureWithResult:(USResult *)result {
    [_cellImageView sd_setImageWithURL:[NSURL URLWithString: result.urls.thumb]
                      placeholderImage:[UIImage imageNamed:@"pixabayPlaceholder"]];
    _cellLabel.text  = result.user.name;
}

- (void)setCellTitleFont:(UIFont *)cellTitleFont {
    _cellTitleFont = cellTitleFont;
    self.cellLabel.font = _cellTitleFont;
}

@end
