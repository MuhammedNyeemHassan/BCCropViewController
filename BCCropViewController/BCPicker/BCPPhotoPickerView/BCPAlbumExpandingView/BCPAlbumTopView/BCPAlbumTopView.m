//
//  BCPAlbumTopView.m
//  BCPicker
//
//  Created by Somoy Das Gupta on 8/4/21.
//

#import "BCPAlbumTopView.h"
#import <Photos/Photos.h>

#define ALBUM_TITLE_LEFT_PADDING (17.0 * ([[UIScreen mainScreen] bounds].size.width / 414.0))
#define ALBUM_TITLE_FONT_SIZE (14.0 * ([[UIScreen mainScreen] bounds].size.width / 414.0))
#define ALBUM_TEXT_COLOR [UIColor colorWithRed:195.0/255.0f green:215.0/255.0f blue:230.0/255.0f alpha:1.0f]

#define ALBUM_ARROW_LEFT_PADDING (10.0 * ([[UIScreen mainScreen] bounds].size.width / 414.0))
#define ALBUM_ARROW_WIDTH (12.0 * ([[UIScreen mainScreen] bounds].size.width / 414.0))
#define ALBUM_ARROW_HEIGHT (7.0 * ([[UIScreen mainScreen] bounds].size.width / 414.0))

#define ALBUM_CAMERA_RIGHT_PADDING (20.0 * ([[UIScreen mainScreen] bounds].size.width / 414.0))
#define ALBUM_CAMERA_WIDTH (26.0 * ([[UIScreen mainScreen] bounds].size.width / 414.0))
#define ALBUM_CAMERA_HEIGHT (26.0 * ([[UIScreen mainScreen] bounds].size.width / 414.0))

#define ALBUM_TOP_VIEW_DEFAULT_BG_COLOR [UIColor colorWithRed:24.0/255.0f green:25.0/255.0f blue:28.0/255.0f alpha:1.0f]

@interface BCPAlbumTopView () {
    BOOL expand;
}

@property (strong, nonatomic) UILabel *albumTitleLabel;
@property (strong, nonatomic) UIImageView *arrowIndicatorImageView;
@property (strong, nonatomic) UIButton *cameraButton;

@end

@implementation BCPAlbumTopView

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
    
    self.backgroundColor = ALBUM_TOP_VIEW_DEFAULT_BG_COLOR;
    
    [self prepareTapGesture];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(albumTopViewTapped:) name:ALBUM_EXPAND_NOTIFICATION object:nil];
    
    [self prepareAlbumTitleLabel];
    [self prepareArrowIndicatorImageView];
    [self prepareCameraButton];
    [self addSubviewConstraints];
}

- (void)prepareTapGesture {
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(albumTopViewTapped:)];
    tap.numberOfTapsRequired = 1;
    self.userInteractionEnabled = YES;
    [self addGestureRecognizer:tap];
}

- (void)prepareAlbumTitleLabel {
    
    CGFloat labelHeight = 25.0;
    CGFloat labelwidth = 80.0;
    _albumTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(ALBUM_TITLE_LEFT_PADDING, self.bounds.size.height/2.0 - labelHeight/2.0, labelwidth, labelHeight)];
    _albumTitleLabel.textColor = ALBUM_TEXT_COLOR;
    _albumTitleFont = [UIFont systemFontOfSize:ALBUM_TITLE_FONT_SIZE];
    _albumTitleLabel.font = _albumTitleFont;
    [self addSubview:_albumTitleLabel];
    
    if ((PHPhotoLibrary.authorizationStatus == PHAuthorizationStatusDenied) || (PHPhotoLibrary.authorizationStatus == PHAuthorizationStatusNotDetermined) || (PHPhotoLibrary.authorizationStatus == PHAuthorizationStatusRestricted))  {
        _albumTitleLabel.hidden = YES;
    }
}

- (void)prepareArrowIndicatorImageView {
    
    _arrowIndicatorImageView = [[UIImageView alloc] initWithFrame:CGRectMake(ALBUM_TITLE_LEFT_PADDING+_albumTitleLabel.bounds.size.width+ALBUM_ARROW_LEFT_PADDING, self.bounds.size.height/2.0 - ALBUM_ARROW_HEIGHT/2.0, ALBUM_ARROW_WIDTH, ALBUM_ARROW_HEIGHT)];
    [self addSubview:_arrowIndicatorImageView];
    
    if ((PHPhotoLibrary.authorizationStatus == PHAuthorizationStatusDenied) || (PHPhotoLibrary.authorizationStatus == PHAuthorizationStatusNotDetermined) || (PHPhotoLibrary.authorizationStatus == PHAuthorizationStatusRestricted))  {
        _arrowIndicatorImageView.hidden = YES;
    }
}

- (void)prepareCameraButton {
    
    _cameraButton = [[UIButton alloc] initWithFrame:CGRectMake(self.bounds.size.width-ALBUM_CAMERA_RIGHT_PADDING-ALBUM_CAMERA_WIDTH, self.bounds.size.height/2.0 - ALBUM_CAMERA_HEIGHT/2.0, ALBUM_CAMERA_WIDTH, ALBUM_CAMERA_HEIGHT)];
    [self addSubview:_cameraButton];
    
    _cameraButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [_cameraButton addTarget:self action:@selector(cameraButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)addSubviewConstraints {
    
    NSDictionary *viewDictionary = NSDictionaryOfVariableBindings(_albumTitleLabel, _arrowIndicatorImageView, _cameraButton);
    
    _albumTitleLabel.translatesAutoresizingMaskIntoConstraints = false;
    _arrowIndicatorImageView.translatesAutoresizingMaskIntoConstraints = false;
    _cameraButton.translatesAutoresizingMaskIntoConstraints = false;
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-%f-[_albumTitleLabel]", ALBUM_TITLE_LEFT_PADDING] options:NSLayoutFormatAlignAllCenterY metrics:nil views:viewDictionary]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_albumTitleLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:[_albumTitleLabel]-%f-[_arrowIndicatorImageView(%f)]", ALBUM_ARROW_LEFT_PADDING, ALBUM_ARROW_WIDTH] options:NSLayoutFormatAlignAllCenterY metrics:nil views:viewDictionary]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[_arrowIndicatorImageView(%f)]", ALBUM_ARROW_HEIGHT] options:NSLayoutFormatAlignAllCenterX metrics:nil views:viewDictionary]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_arrowIndicatorImageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
    _arrowIndicatorImageView.image = [UIImage imageNamed:@"albumDownArrow"];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:[_cameraButton(%f)]-(%f)-|", ALBUM_CAMERA_WIDTH, ALBUM_CAMERA_RIGHT_PADDING] options:NSLayoutFormatAlignAllCenterY metrics:nil views:viewDictionary]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[_cameraButton(%f)]", ALBUM_CAMERA_HEIGHT] options:NSLayoutFormatAlignAllCenterX metrics:nil views:viewDictionary]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_cameraButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
    [_cameraButton setImage:[UIImage imageNamed:@"albumCamera"] forState:UIControlStateNormal];
}

//MARK:- Property Setters
- (void)setAlbum:(PHAssetCollection *)album {
    _album = album;
    _albumTitleLabel.text = _album.localizedTitle;
    
    _albumTitleLabel.hidden = NO;
    _arrowIndicatorImageView.hidden = NO;
}

- (void)setAlbumTitleFont:(UIFont *)albumTitleFont {
    _albumTitleFont = albumTitleFont;
    _albumTitleLabel.font = _albumTitleFont;
}

- (void)setAlbumTitleColor:(UIColor *)albumTitleColor {
    _albumTitleColor = albumTitleColor;
    _albumTitleLabel.textColor = _albumTitleColor;
}

- (void)setBgColor:(UIColor *)bgColor {
    _bgColor = bgColor;
    self.backgroundColor = _bgColor;
}

//MARK:- Touch Actions
- (void)cameraButtonPressed:(UIButton*)sender {
    if ([_delegate respondsToSelector:@selector(cameraButtonTapped)]) {
        [_delegate cameraButtonTapped];
    }
}

- (void)albumTopViewTapped:(UITapGestureRecognizer*)sender {
    
    if (@available(iOS 14, *)) {
        
        if (PHPhotoLibrary.authorizationStatus == PHAuthorizationStatusAuthorized || PHPhotoLibrary.authorizationStatus == PHAuthorizationStatusLimited) {
            
            [self callExpandDelegate];
        }
    }
    else {
        
        if (PHPhotoLibrary.authorizationStatus == PHAuthorizationStatusAuthorized) {
            [self callExpandDelegate];
        }
    }
}

- (void)callExpandDelegate {
    
    if ([_delegate respondsToSelector:@selector(expandAlbumView:)]) {
        
        expand = !expand;
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.3];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        _arrowIndicatorImageView.transform = CGAffineTransformRotate(_arrowIndicatorImageView.transform, M_PI);
        [UIView commitAnimations];
        
        [_delegate expandAlbumView:expand];
    }
}
@end
