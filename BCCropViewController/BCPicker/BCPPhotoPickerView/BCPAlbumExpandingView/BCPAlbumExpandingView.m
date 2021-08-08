//
//  BCPAlbumExpandingView.m
//  BCPicker
//
//  Created by Somoy Das Gupta on 8/4/21.
//

#import "BCPAlbumExpandingView.h"
#import "BCPAlbumTopView.h"
#import "BCPAlbumTableViewCell.h"

#define ALBUM_TOP_VIEW_DEFAULT_HEIGHT (44.0 * ([[UIScreen mainScreen] bounds].size.width / 414.0))

#define ALBUM_DEFAULT_BG_COLOR [UIColor colorWithRed:24.0/255.0f green:25.0/255.0f blue:28.0/255.0f alpha:0.5f]

#define ALBUM_DEFAULT_BORDER_COLOR [UIColor colorWithRed:35.0/255.0f green:37.0/255.0f blue:41.0/255.0f alpha:0.5f]
#define ALBUM_DEFAULT_BORDER_HEIGHT (1.0 * ([[UIScreen mainScreen] bounds].size.width / 414.0))

#define ALBUM_CELL_DEFAULT_HEIGHT (80.0 * ([[UIScreen mainScreen] bounds].size.width / 414.0))

@interface BCPAlbumExpandingView ()<UITableViewDelegate, UITableViewDataSource, BCPAlbumTopViewDelegate>

@property (strong, nonatomic) BCPAlbumTopView *albumTopView;
@property (strong, nonatomic) UIView *transparentView;
@property (strong, nonatomic) UIView *bottomBorderView;
@property (strong, nonatomic) UITableView *albumTableView;
@property (strong, nonatomic) NSLayoutConstraint *albumTableViewHeightConstraint;
@end

@implementation BCPAlbumExpandingView

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
    self.backgroundColor = UIColor.clearColor;
    self.clipsToBounds = YES;
    
    [self prepareTransparentView];
    [self prepareAlbumTopView];
    [self prepareAlbumTableView];
    [self prepareBottomBorderView];
}

- (void)prepareAlbumTopView {
    _albumTopView = [[BCPAlbumTopView alloc] initWithFrame:self.bounds];
    _albumTopView.delegate = self;
    [self addSubview:_albumTopView];
}

- (void)prepareTransparentView {
    _transparentView = [[UIView alloc] initWithFrame:self.bounds];
    _transparentView.backgroundColor = UIColor.clearColor;
    [self addSubview:_transparentView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(transparentViewTapped:)];
    [_transparentView addGestureRecognizer:tap];
}

- (void)prepareBottomBorderView {
    _bottomBorderView = [[UIView alloc] initWithFrame:CGRectMake(0, self.bounds.size.height - ALBUM_DEFAULT_BORDER_HEIGHT, self.bounds.size.width, ALBUM_DEFAULT_BORDER_HEIGHT)];
    _bottomBorderView.backgroundColor = ALBUM_DEFAULT_BORDER_COLOR;
    [self addSubview:_bottomBorderView];
}

- (void)prepareAlbumTableView {
    _albumTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, _albumTopView.bounds.size.height, self.bounds.size.width, 0) style:UITableViewStylePlain];
    _albumTableView.backgroundColor = UIColor.clearColor;
    _albumTableView.bounces = NO;
    _albumTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [_albumTableView registerNib:[UINib nibWithNibName:@"BCPAlbumTableViewCell" bundle:nil] forCellReuseIdentifier:@"BCPAlbumTableViewCell"];
    
    [self addSubview:_albumTableView];
}

- (void)addSubviewConstraint {
    
    NSDictionary *viewDictionary = NSDictionaryOfVariableBindings(_albumTopView, _albumTableView, _transparentView, _bottomBorderView);
    _albumTopView.translatesAutoresizingMaskIntoConstraints = false;
    _albumTableView.translatesAutoresizingMaskIntoConstraints = false;
    _transparentView.translatesAutoresizingMaskIntoConstraints = false;
    _bottomBorderView.translatesAutoresizingMaskIntoConstraints = false;
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_albumTopView]-0-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:viewDictionary]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_albumTableView]-0-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:viewDictionary]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-0-[_albumTopView(<=%f)]-0-[_albumTableView]", ALBUM_TOP_VIEW_DEFAULT_HEIGHT] options:NSLayoutFormatAlignAllCenterX metrics:nil views:viewDictionary]];
    _albumTableViewHeightConstraint = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[_albumTableView(0)]" options:NSLayoutFormatAlignAllCenterX metrics:nil views:viewDictionary].firstObject;
    [_albumTableView addConstraint:_albumTableViewHeightConstraint];
    
    NSLayoutConstraint *albumTopHeightRatioConstraint = [NSLayoutConstraint constraintWithItem:_albumTopView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0];
    albumTopHeightRatioConstraint.priority = UILayoutPriorityDefaultHigh;
    [self addConstraint: albumTopHeightRatioConstraint];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_transparentView]-0-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:viewDictionary]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[_transparentView]-0-|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:viewDictionary]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_bottomBorderView]-0-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:viewDictionary]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_bottomBorderView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_albumTableView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_bottomBorderView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:ALBUM_DEFAULT_BORDER_HEIGHT]];
}

//MARK:- Action Methods
- (void)transparentViewTapped:(UITapGestureRecognizer*)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:ALBUM_EXPAND_NOTIFICATION object:nil];
}

//MARK:- Property Setters
- (void)setAllAlbums:(NSArray<PHAssetCollection *> *)allAlbums {
    if (!_albumTableView.constraints.count) {
        [self addSubviewConstraint];
    }
    
    _allAlbums = allAlbums;
    
    if (_albumTopView.album) {
        [_albumTableView reloadData];
        
        PHAssetCollection *selectedAlbum;
        
        for (PHAssetCollection *assetCollection in _allAlbums) {
            if ([_albumTopView.album.localizedTitle isEqual:assetCollection.localizedTitle]) {
                selectedAlbum = assetCollection;
            }
        }
        
        _albumTopView.album = selectedAlbum;
        NSUInteger index = [_allAlbums indexOfObject:selectedAlbum];
        
        if ([_delegate respondsToSelector:@selector(reloadAllPhotos:)]) {
            [_delegate reloadAllPhotos:index];
        }
    }
    else {
        _albumTopView.album = _allAlbums.firstObject;
        _albumTopView.delegate = self;
        
        _albumTableView.delegate = self;
        _albumTableView.dataSource = self;
        [_albumTableView reloadData];
    }
}

- (void)setSelectedAlbumFont:(UIFont *)selectedAlbumFont {
    _selectedAlbumFont = selectedAlbumFont;
    _albumTopView.albumTitleFont = _selectedAlbumFont;
}

- (void)setAlbumFont:(UIFont *)albumFont {
    _albumFont = albumFont;
    [_albumTableView reloadData];
}

//MARK:- UITableViewDelegate, UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _allAlbums.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    BCPAlbumTableViewCell *cell = (BCPAlbumTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"BCPAlbumTableViewCell"];
    
    cell.album = _allAlbums[indexPath.row];
    
    if (_albumFont)
        cell.albumTitleFont = _albumFont;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return ALBUM_CELL_DEFAULT_HEIGHT;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    
    _albumTopView.album = _allAlbums[indexPath.item];
    _selectedAlbumIndex = indexPath.item;
    
    if ([_delegate respondsToSelector:@selector(didAlbumSelected:)]) {
        [_delegate didAlbumSelected:indexPath.item];
    }
}

//MARK:- AlbumTopViewDelegate
- (void)cameraButtonTapped {
    if ([_delegate respondsToSelector:@selector(cameraButtonTapped)]) {
        [_delegate cameraButtonTapped];
    }
}

- (void)expandAlbumView:(BOOL)expand {
    
    if (expand) {
        CGFloat tableViewHeight = (_allAlbums.count > 2 ? 3.0 : _allAlbums.count) * ALBUM_CELL_DEFAULT_HEIGHT;
        _albumTableViewHeightConstraint.constant = tableViewHeight;
    }
    else {
        _albumTableViewHeightConstraint.constant = 0.0;
    }
    
    if ([_delegate respondsToSelector:@selector(expandAlbumView:)]) {
        [_delegate expandAlbumView:expand];
    }
}

@end
