//
//  BCPPhotoPickerCell.m
//  BCPicker
//
//  Created by Somoy Das Gupta on 7/2/21.
//

#import "BCPPhotoPickerCell.h"

@interface BCPPhotoPickerCell ()

@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;
@end

@implementation BCPPhotoPickerCell

- (void)dealloc
{
    self.photoImageView.image = nil;
}

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
    self.layer.cornerRadius= 3.0f;
    self.layer.borderWidth = 1.0f;
    self.layer.borderColor = [UIColor colorWithRed:50.0/255.0 green:52.0/255.0 blue:60.0/255.0 alpha:1].CGColor;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.imageRequestID = 0;
    self.photoImageName = nil;
    self.photoAsset = nil;
    self.photoImageView.image = nil;
}

- (void)setPhotoImageName:(NSString * _Nullable)photoImageName {
    _photoImageName = photoImageName;
    
    if (_photoImageName) {
        _photoImageView.image = [UIImage imageNamed:_photoImageName];
    }
}

- (void)setPhotoAsset:(PHAsset *)photoAsset {
    _photoAsset = photoAsset;
    
    if (_photoAsset) {
        PHImageRequestOptions *option = [PHImageRequestOptions new];
//        option.networkAccessAllowed = YES;
        option.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
        option.version = PHImageRequestOptionsVersionCurrent;
        option.resizeMode = PHImageRequestOptionsResizeModeExact;
        
        NSInteger scale = 2;
        self.imageRequestID = [[PHImageManager defaultManager] requestImageForAsset:_photoAsset targetSize:CGSizeMake(scale * self.bounds.size.width, scale * self.bounds.size.height) contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSNumber *currentRequestID = info[PHImageResultRequestIDKey];
                if (self.imageRequestID == [currentRequestID intValue] + 999)
                    self->_photoImageView.image = result;
            });
        }] + 999;
    }
}

@end
