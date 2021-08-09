//
//  BCPPhotoPickerView.m
//  BCPicker
//
//  Created by Somoy Das Gupta on 28/1/21.
//

#import "BCPPhotoPickerView.h"
#import "BCPAlbumExpandingView.h"
#import "BCPAllowAccessView.h"
#import "BCPPhotoPickerCell.h"
#import "ATPCustomProgressView.h"
#import "BCPicker.h"

#define ALBUM_VIEW_DEFAULT_HEIGHT (44.0 * ([[UIScreen mainScreen] bounds].size.width / 414.0))
#define ALBUM_DEFAULT_BG_COLOR [UIColor colorWithRed:24.0/255.0f green:25.0/255.0f blue:28.0/255.0f alpha:0.5f]

#define PHOTO_COLLECTION_TOP_DOWN_INSET (10.0 * ([[UIScreen mainScreen] bounds].size.width / 414.0))
#define PHOTO_COLLECTION_LEFT_RIGHT_INSET (14.0 * ([[UIScreen mainScreen] bounds].size.width / 414.0))
#define PHOTO_COLLECTION_INTER_ITEM_SPACING (10.0 * ([[UIScreen mainScreen] bounds].size.width / 414.0))
#define PHOTO_COLLECTION_LINE_SPACING (10.0 * ([[UIScreen mainScreen] bounds].size.width / 414.0))

@interface BCPPhotoPickerView() <BCPAlbumExpandingViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, PHPhotoLibraryChangeObserver> {
    dispatch_once_t onceTokenForPickerLoad;
    
    BCPAlbumExpandingView *albumView;
    NSLayoutConstraint *albumViewHeightConstraint;
    
    UICollectionView *collectionView;
    NSLayoutConstraint *collectionViewTopConstraint;
    BCPAllowAccessView *allowAccessView;
    
    NSMutableArray<PHAssetCollection *> *allAlbums;
    PHFetchResult<PHAsset *> *allPhotos;
    NSArray *topCellImages;
}

@property (strong, nonatomic) UIView *transparentView;

@end

@implementation BCPPhotoPickerView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    
    [self prepareCollectionView];
    [self prepareAllowAccessView];
    [self prepareAlbumView];
    [self prepareTransparentView];
    
    [self addSubviewConstraints];
}

- (void)prepareAlbumView {
    albumView = [[BCPAlbumExpandingView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, ALBUM_VIEW_DEFAULT_HEIGHT)];
    [self addSubview:albumView];
    albumView.delegate = self;
}

- (void)prepareTransparentView {
    _transparentView = [[UIView alloc] initWithFrame:collectionView.bounds];
    _transparentView.backgroundColor = ALBUM_DEFAULT_BG_COLOR;
    [collectionView addSubview:_transparentView];
    _transparentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _transparentView.hidden = true;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(transparentViewTapped:)];
    [_transparentView addGestureRecognizer:tap];
}

- (void)prepareCollectionView {
    UICollectionViewFlowLayout* flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    
    CGRect collectionViewFrame = CGRectMake(0, ALBUM_VIEW_DEFAULT_HEIGHT, self.bounds.size.width, self.bounds.size.height - ALBUM_VIEW_DEFAULT_HEIGHT);
    collectionView = [[UICollectionView alloc] initWithFrame:collectionViewFrame collectionViewLayout:flowLayout];
    [self addSubview:collectionView];
    collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    collectionView.backgroundColor = UIColor.clearColor;
    
    [collectionView registerNib:[UINib nibWithNibName:@"BCPPhotoPickerCell" bundle:nil] forCellWithReuseIdentifier:@"BCPPhotoPickerCell"];
    
    collectionView.delegate = self;
    collectionView.dataSource = self;
    
    topCellImages = @[@"Group 6533", @"Group 6532", @"Group 6531"];
}

- (void)prepareAllowAccessView {
    allowAccessView = [[BCPAllowAccessView alloc] initWithFrame:collectionView.bounds];
    [collectionView addSubview:allowAccessView];
    allowAccessView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

- (void)addSubviewConstraints {
    
    NSDictionary *viewDictionary = NSDictionaryOfVariableBindings(collectionView, albumView);
    
    albumView.translatesAutoresizingMaskIntoConstraints = false;
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[albumView]-0-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:viewDictionary]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[albumView]" options:NSLayoutFormatAlignAllCenterX metrics:nil views:viewDictionary]];
    albumViewHeightConstraint = [NSLayoutConstraint constraintWithItem:albumView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:0];
    [albumView addConstraint:albumViewHeightConstraint];
    
    collectionView.translatesAutoresizingMaskIntoConstraints = false;
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[collectionView]-0-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:viewDictionary]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[collectionView]-0-|"  options:NSLayoutFormatAlignAllCenterX metrics:nil views:viewDictionary]];
    
    collectionViewTopConstraint = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-0-[collectionView]"] options:NSLayoutFormatAlignAllCenterX metrics:nil views:viewDictionary].firstObject;
    [self addConstraints:@[collectionViewTopConstraint]];
}

//MARK:- Delegate
- (void)setDelegate:(id<BCPPhotoPickerViewDelegate>)delegate {
    _delegate = delegate;
    if ([delegate conformsToProtocol:@protocol(BCPAllowAccessViewDelegate)]) {
        allowAccessView.delegate = (id<BCPAllowAccessViewDelegate>)delegate;
    }
}

//MARK:- Property Setters
- (void)setSelectedAlbumFont:(UIFont *)selectedAlbumFont {
    _selectedAlbumFont = selectedAlbumFont;
    albumView.selectedAlbumFont = _selectedAlbumFont;
}

- (void)setAlbumFont:(UIFont *)albumFont {
    _albumFont = albumFont;
    albumView.albumFont = albumFont;
}

- (void)setAccessoryViewType:(BCPPhotoPickerAccessoryViewType)accessoryViewType {
    _accessoryViewType = accessoryViewType;
    collectionViewTopConstraint.constant = _accessoryViewType == BCPPhotoAlbumView ? ALBUM_VIEW_DEFAULT_HEIGHT : 0.0;
    albumViewHeightConstraint.constant = _accessoryViewType == BCPPhotoAlbumView ? ALBUM_VIEW_DEFAULT_HEIGHT : 0.0;;
    [self layoutIfNeeded];
}

//MARK:- Load Album & Photos
- (void)loadAllAlbums {
    
    [self fetchAllAlbums];
    [self loadAllPhotosFromAlbum:allAlbums[albumView.selectedAlbumIndex]];
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
}

- (void)fetchAllAlbums {
    allAlbums = [[NSMutableArray<PHAssetCollection*> alloc] init];
    
    PHFetchResult<PHAssetCollection*> *allCollections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
    
    PHFetchOptions *assetoptions = [PHFetchOptions new];
    assetoptions.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d", PHAssetMediaTypeImage];
    
    for (PHAssetCollection *collection in allCollections) {
        if ([PHAsset fetchAssetsInAssetCollection:collection options:assetoptions].count) {
            [allAlbums addObject:collection];
        }
    }
    
    albumView.allAlbums = allAlbums;
}

- (void)loadAllPhotosFromAlbum:(PHAssetCollection*)collection {
    
    PHFetchOptions *options = [PHFetchOptions new];
    options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d", PHAssetMediaTypeImage];
    allPhotos = [PHAsset fetchAssetsInAssetCollection:collection options:options];
    dispatch_async(dispatch_get_main_queue(), ^{
        self->allowAccessView.hidden = YES;
        [self->collectionView reloadData];
    });
}

- (void)loadAllPhotos {
    
    PHFetchResult *assetCollections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
    
    if(assetCollections) {
        [self loadAllPhotosFromAlbum:assetCollections.firstObject];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self->allowAccessView.hidden = YES;
        [self->collectionView reloadData];
    });
    
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
}

- (void)loadAllSelectedPhotos {
    
    allPhotos = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:nil];
    allowAccessView.hidden = allPhotos.count > 0;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self->allowAccessView.hidden = YES;
        [self->collectionView reloadData];
    });
    
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
}

//MARK:- PHPhotoLibraryChangeObserver
- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (self->_accessoryViewType == BCPPhotoAlbumView) {
            [self fetchAllAlbums];
        }
        else {
            
            
            if (@available(iOS 14, *)) {
                PHAuthorizationStatus phStatus = [PHPhotoLibrary authorizationStatusForAccessLevel:PHAccessLevelReadWrite];
                
                if (phStatus == PHAuthorizationStatusLimited) {
                    [self loadAllSelectedPhotos];
                }
                else {
                    [self loadAllPhotos];
                }
            }
            else {
                [self loadAllPhotos];
            }
        }
    });
}

//MARK:- UICollectionViewDataSource,UICollectionViewDelegateFlowLayout
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    return UIEdgeInsetsMake(PHOTO_COLLECTION_TOP_DOWN_INSET, PHOTO_COLLECTION_LEFT_RIGHT_INSET, PHOTO_COLLECTION_TOP_DOWN_INSET, PHOTO_COLLECTION_LEFT_RIGHT_INSET);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section{
    return PHOTO_COLLECTION_INTER_ITEM_SPACING;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return PHOTO_COLLECTION_LINE_SPACING;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    CGFloat width = floor(((UIScreen.mainScreen.bounds.size.width - PHOTO_COLLECTION_LEFT_RIGHT_INSET * 2.0 - PHOTO_COLLECTION_INTER_ITEM_SPACING * 2.0) / 3.0) * 100) / 100.0;
    
    if (_accessoryViewType == BCPPhotoCellView && indexPath.row < 3) {
        CGFloat height = width * (90.0 / 122.0);
        return CGSizeMake(width, height);
    }
    
    return CGSizeMake(width, width);
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    BCPPhotoPickerCell *cell = (BCPPhotoPickerCell*)[collectionView dequeueReusableCellWithReuseIdentifier:@"BCPPhotoPickerCell" forIndexPath:indexPath];
    
    if (_accessoryViewType == BCPPhotoAlbumView) {
        
        NSUInteger newIndex = allPhotos.count - indexPath.item - 1;
        cell.photoAsset = allPhotos[newIndex];
    }
    else {
        
        if (indexPath.item < 3) {
            cell.photoImageName = topCellImages[indexPath.item];
        }
        else
        {
            //Array currently in reverse format, we need to get asset from last
            NSUInteger index = indexPath.row - 3;
            NSUInteger newIndex = allPhotos.count - index - 1;
            cell.photoAsset = allPhotos[newIndex];
        }
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    
    BCPPhotoPickerCell *photoCell = (BCPPhotoPickerCell*)cell;
    [[PHImageManager defaultManager] cancelImageRequest:photoCell.imageRequestID];
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    if (!allPhotos)
        return 0; 
    
    if (_accessoryViewType == BCPPhotoCellView) {
        return allPhotos.count + 3;
    } else {
        return allPhotos.count;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    BCPPhotoPickerViewAction actionType;
    
    if (_accessoryViewType == BCPPhotoCellView && indexPath.item < 3) {
        switch (indexPath.item) {
            case 1: {
                actionType = BCPPhoto;
                break;
            }
            case 2: {
                actionType = BCPFileManager;
                break;
            }
            default:
                actionType = BCPCamera;
                break;
        }

        if ([self.delegate respondsToSelector:@selector(pickerCellPressed:)]) {
            [self.delegate pickerCellPressed:actionType];
        }
    } else {
        
        BCPPhotoPickerCell *cell = (BCPPhotoPickerCell*)[collectionView cellForItemAtIndexPath:indexPath];
        
        __block PHImageRequestID requestID = 888;
        
        static BOOL isProcessing = NO;
        if (!isProcessing) {
            isProcessing = YES;
            
            PHImageRequestOptions *option = [PHImageRequestOptions new];
            option.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
            option.networkAccessAllowed = YES;
            option.version = PHImageRequestOptionsVersionCurrent;
            option.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [ATPCustomProgressView showLoadingViewWithText:[NSString stringWithFormat:@"Downloading! Please don’t close or\n Lock your device."] withProgress:progress withCancelationBlock:^(BOOL cancelled) {
                        if (cancelled) {
                            [[PHImageManager defaultManager] cancelImageRequest:(requestID - 888)];
                            isProcessing = NO;
                        }
                    }];
                });
            };
            
            requestID += [[PHImageManager defaultManager] requestImageForAsset:cell.photoAsset targetSize:CGSizeMake(cell.photoAsset.pixelWidth, cell.photoAsset.pixelHeight) contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if (result != nil && [self.delegate respondsToSelector:@selector(pickerDidSelectImage:)]) {
                        [self.delegate pickerDidSelectImage:result];
                        [ATPCustomProgressView removeLoadingView];
                    }
                    
                    if (info[PHImageErrorKey]) {
                        NSError *error = info[PHImageErrorKey];
                        if (error.code == NSURLErrorNotConnectedToInternet) {
                            UIAlertController *noInternetAlert = [UIAlertController alertControllerWithTitle:@"No Internet!" message:@"Please connect to internet to download image." preferredStyle:UIAlertControllerStyleAlert];
                            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleCancel handler:nil];
                            
                            [noInternetAlert addAction:ok];
                            [((BCPicker*)self->_delegate) presentViewController:noInternetAlert animated:true completion:nil];
                        }
                    }
                    isProcessing = NO;
                });
            }];
        }
    }
}

//MARK:- BCPAlbumExpandingViewDelegate
- (void)cameraButtonTapped {
    if ([self.delegate respondsToSelector:@selector(pickerCellPressed:)]) {
        [self.delegate pickerCellPressed:BCPCamera];
    }
}

- (void)expandAlbumView:(BOOL)expand {
    if (expand) {
        albumViewHeightConstraint.constant = self.bounds.size.height;
        _transparentView.hidden = NO;
    }
    else {
        albumViewHeightConstraint.constant = ALBUM_VIEW_DEFAULT_HEIGHT;
        _transparentView.hidden = YES;
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        [self layoutIfNeeded];
    }];
}

- (void)didAlbumSelected:(NSUInteger)index {
    PHAssetCollection *album = allAlbums[index];
    [self loadAllPhotosFromAlbum:album];
    [self transparentViewTapped:nil];
}

- (void)reloadAllPhotos:(NSUInteger)albumIndex {
    PHAssetCollection *album = allAlbums[albumIndex];
    [self loadAllPhotosFromAlbum:album];
}

//MARK:- Action Methods
- (void)transparentViewTapped:(UITapGestureRecognizer*)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Expand" object:nil];
}
@end
