//
//  NCCanvasCollectionViewCell.m
//  NoCrop
//
//  Created by Kazi Muhammad Tawsif Jamil on 3/4/21.
//

#import "NCCanvasCollectionViewCell.h"

@implementation NCCanvasCollectionViewCell

- (void)setImageDictionary:(NSDictionary<NSString *,NSString *> *)imageDictionary {
    _imageDictionary = imageDictionary;
    
    NSString *imageName;
    if (self.isSelected && _imageDictionary) {
        imageName = _imageDictionary[@"Selected"];
    }
    else {
        imageName = _imageDictionary[@"Unselected"];
    }
    self.canvasCollectionViewCellImageView.image = [UIImage imageNamed:imageName];;
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

-(void)setSeperatorVisible:(BOOL)seperatorVisible{
    _seperatorVisible = seperatorVisible;
    self.seperator.hidden = !seperatorVisible;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    
    NSString *imageName;
    if (self.isSelected && self.imageDictionary) {
        imageName = self.imageDictionary[@"Selected"];
    }
    else {
        imageName = self.imageDictionary[@"Unselected"];
    }
    self.canvasCollectionViewCellImageView.image = [UIImage imageNamed:imageName];;
}

-(void)prepareForReuse{
    [super prepareForReuse];
    self.seperator.hidden = YES;
}

@end
