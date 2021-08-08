//
//  BCPicker.m
//  BCPicker
//
//  Created by Somoy Das Gupta on 28/1/21.
//

#import "BCPicker.h"
#import "BCMenuBarView.h"
#import <Photos/Photos.h>
#import "BCPPhotoPickerView.h"
#import "BCPAllowAccessView.h"
#import "BCPApiPhotoPickerView.h"
#import <MobileCoreServices/MobileCoreServices.h>

#define NAVIGATION_TITLE_DEFAULT_COLOR [UIColor colorWithRed:255.0/255.0f green:255.0/255.0f blue:255.0/255.0f alpha:1.0f]

@interface BCPicker ()<BCMenuBarViewDelegate, BCMenuBarViewDatasouce, UIScrollViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, BCPPhotoPickerViewDelegate, BCPAllowAccessViewDelegate, UIDocumentPickerDelegate, BCPColorPickerViewDelegate, BCPApiPhotoPickerViewDelegate> {
    
    NSArray *navBarTitles;
    NSArray *tabBarTitles;
    
    NSMutableArray *addedOptions;
    NSMutableArray *addedOptionsTitle;
    
    bool tabBarItemPressed;
    BCPPhotoPickerViewAction photoPickerAction;
}
@property (weak, nonatomic) IBOutlet BCMenuBarView *menuBar;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end

@implementation BCPicker

- (instancetype)init
{
    self = [super init];
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
    addedOptions = [NSMutableArray new];
    addedOptionsTitle = [NSMutableArray new];
    [self prepareTabBarData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _collectionView.showsHorizontalScrollIndicator = false;
    [_collectionView setPrefetchingEnabled:NO];
    
    [self prepareNavbar];
    [self prepareBCMenuBarView];
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
    [self.collectionView reloadData];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self.collectionView reloadData];
}

//MARK:- Prepare Methods
- (void)prepareTabBarData {
    tabBarTitles = @[@"Camera Roll",@"Color",@"Unsplash",@"Pixabay",@"Google Photos"];
    navBarTitles = @[@"SELECT PHOTO", @"SELECT COLOR", @"DOWNLOAD PHOTO", @"DOWNLOAD PHOTO", @"DOWNLOAD PHOTO"];
}

- (void)prepareNavbar {
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationItem.title = navBarTitles.firstObject;
    self.navigationController.navigationBar.titleTextAttributes = @{NSFontAttributeName : _navigationBarTitleFont, NSForegroundColorAttributeName : NAVIGATION_TITLE_DEFAULT_COLOR};
}

- (void)prepareBCMenuBarView {
    
    _menuBar.menuFont = _menuFont;
    _menuBar.menuSelectedFont = _menuSelectedFont;
    
    _menuBar.delegate = self;
    _menuBar.dataSource = self;
    
    _menuBar.defaultSelectedIndex = 0;
}

//MARK:- Property Setters
- (void)setPickerOptions:(BCPickerOptions)pickerOptions {
    _pickerOptions = pickerOptions;
    
    if (_pickerOptions & Photos) {
        [addedOptions addObject:tabBarTitles[0]];
        [addedOptionsTitle addObject:navBarTitles[0]];
    }
    
    if (_pickerOptions & Colors) {
        [addedOptions addObject:tabBarTitles[1]];
        [addedOptionsTitle addObject:navBarTitles[1]];
    }
    
    if (_pickerOptions & Unsplash) {
        [addedOptions addObject:tabBarTitles[2]];
        [addedOptionsTitle addObject:navBarTitles[2]];
    }
    
    if (_pickerOptions & Pixabay) {
        [addedOptions addObject:tabBarTitles[3]];
        [addedOptionsTitle addObject:navBarTitles[3]];
    }
    
    if (_pickerOptions & GooglePhotos) {
        [addedOptions addObject:tabBarTitles[4]];
        [addedOptionsTitle addObject:navBarTitles[4]];
    }
}

- (void)setNavigationBarTitleFont:(UIFont *)navigationBarTitleFont {
    _navigationBarTitleFont = navigationBarTitleFont;
    self.navigationController.navigationBar.titleTextAttributes = @{NSFontAttributeName : _navigationBarTitleFont, NSForegroundColorAttributeName : NAVIGATION_TITLE_DEFAULT_COLOR};
}

- (void)setMenuFont:(UIFont *)menuFont {
    _menuFont = menuFont;
    _menuBar.menuFont = _menuFont;
}

- (void)setMenuSelectedFont:(UIFont *)menuSelectedFont {
    _menuSelectedFont = menuSelectedFont;
    _menuBar.menuSelectedFont = _menuSelectedFont;
}

- (void)setAlbumFont:(UIFont *)albumFont {
    _albumFont = albumFont;
}

- (void)setSelectedAlbumFont:(UIFont *)selectedAlbumFont {
    _selectedAlbumFont = selectedAlbumFont;
}

//MARK:- Button Action
- (IBAction)downArrowPressed:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}

//MARK:- UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.view endEditing:true];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView == _collectionView) {
        
        NSInteger currentIndex = round(self.collectionView.contentOffset.x / self.collectionView.frame.size.width);
        
        if (currentIndex != _menuBar.defaultSelectedIndex) {
            
            _menuBar.defaultSelectedIndex = currentIndex;
            self.navigationItem.title = addedOptionsTitle[currentIndex];
            
            NSString *pickerOption = addedOptions[currentIndex];
            
            if ([pickerOption isEqualToString:@"Unsplash"]) {
                
                UICollectionViewCell *cell = [_collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:currentIndex inSection:0]];
                BCPApiPhotoPickerView *contentView = (BCPApiPhotoPickerView*)cell.contentView;
                
                if (_unsplashAPIKey != nil && contentView.apiKey == nil) {
                    contentView.apiKey = _unsplashAPIKey;
                }
            }
            else if ([pickerOption isEqualToString:@"Pixabay"]) {
                
                UICollectionViewCell *cell = [_collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:currentIndex inSection:0]];
                BCPApiPhotoPickerView *contentView = (BCPApiPhotoPickerView*)cell.contentView;
                
                if (_pixabayAPIKey != nil && contentView.apiKey == nil) {
                    contentView.apiKey = _pixabayAPIKey;
                }
            }
        }
    }
}


//MARK:- BCMenuBarView Datasource & Delegate
- (NSArray<NSString *> *)menuTitlesForMenuView:(BCMenuBarView *)menuView {
    return addedOptions;
}

- (void)menuView:(BCMenuBarView *)menuView didSelectedAtIndex:(NSInteger)index {
    [self.view endEditing:true];
    tabBarItemPressed = true;
    self.navigationItem.title = addedOptionsTitle[index];
    
    [_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:YES];
}

//MARK:- UICollectionViewDataSource,UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return collectionView.frame.size;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (tabBarItemPressed && _menuBar.defaultSelectedIndex == indexPath.item) {
        NSString *pickerOption = addedOptions[indexPath.item];
        
        if ([pickerOption isEqualToString:@"Unsplash"]) {
            
            BCPApiPhotoPickerView *contentView = (BCPApiPhotoPickerView*)cell.contentView;
            
            if (self->_unsplashAPIKey != nil && contentView.apiKey == nil) {
                contentView.apiKey = self->_unsplashAPIKey;
            }
        }
        else if ([pickerOption isEqualToString:@"Pixabay"]) {
            
            BCPApiPhotoPickerView *contentView = (BCPApiPhotoPickerView*)cell.contentView;
            
            if (self->_pixabayAPIKey != nil && contentView.apiKey == nil) {
                contentView.apiKey = self->_pixabayAPIKey;
            }
        }
        
        tabBarItemPressed = false;
    }
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UICollectionViewCell *cell;
    
    NSString *pickerOption = addedOptions[indexPath.item];
    
    if ([pickerOption isEqualToString:@"Camera Roll"])
    {
         cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell0" forIndexPath:indexPath];
        
        BCPPhotoPickerView *contentView = (BCPPhotoPickerView*)cell.contentView;
        contentView.delegate = self;
        
        if (contentView.accessoryViewType != _photoPickerAccessoryViewType)
            contentView.accessoryViewType = _photoPickerAccessoryViewType;
        
        if (_albumFont)
            contentView.albumFont = _albumFont ;
        
        if (_selectedAlbumFont)
            contentView.selectedAlbumFont = _selectedAlbumFont;
        
        if (_menuBar.defaultSelectedIndex == 0) {
            
            PHAuthorizationStatus phPermission;
            if (@available(iOS 14, *)) {
                phPermission = [PHPhotoLibrary authorizationStatusForAccessLevel:PHAccessLevelReadWrite];
            }
            else {
                phPermission = [PHPhotoLibrary authorizationStatus];
            }
            
            [self checkPermission:phPermission handler:^(BOOL isAuthorized) {
                
                if (isAuthorized) {
                    
                    if (self->_photoPickerAccessoryViewType == BCPPhotoAlbumView) {
                        [contentView loadAllAlbums];
                    }
                    else {
                        if (@available(iOS 14, *)) {
                            if (phPermission == PHAuthorizationStatusLimited) {
                                [contentView loadAllSelectedPhotos];
                            }
                            else {
                                [contentView loadAllPhotos];
                            }
                        } else {
                            [contentView loadAllPhotos];
                        }
                    }
                }
            }];
        }
    }
    else if ([pickerOption isEqualToString:@"Color"])
    {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell1" forIndexPath:indexPath];
        
        BCPColorPickerView *contentView = (BCPColorPickerView*)cell.contentView;
        contentView.delegate = self;
        contentView.colorGroupTitles = self.colorGroupTitles;
        contentView.colorPlistGroupArray = self.colorPlistGroupArray;
    }
    else if ([pickerOption isEqualToString:@"Unsplash"])
    {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell2" forIndexPath:indexPath];
        
        BCPApiPhotoPickerView *contentView = (BCPApiPhotoPickerView*)cell.contentView;
        
        if (_apiSearchTextFont)
            contentView.searchTextFont = _apiSearchTextFont;
        
        if (_apiPhotoTitleFont)
            contentView.photoTitleFont = _apiPhotoTitleFont;
        
        contentView.delegate = self;
    }
    else if ([pickerOption isEqualToString:@"Pixabay"])
    {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell3" forIndexPath:indexPath];
        
        BCPApiPhotoPickerView *contentView = (BCPApiPhotoPickerView*)cell.contentView;
        
        if (_apiSearchTextFont)
            contentView.searchTextFont = _apiSearchTextFont;
        
        if (_apiPhotoTitleFont)
            contentView.photoTitleFont = _apiPhotoTitleFont;
        
        contentView.delegate = self;
    }
    else if ([pickerOption isEqualToString:@"Google Photos"]) {
        
    }
    
    return cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return addedOptions.count;
}

//MARK:- PhotoPickerViewDelegate
- (void)pickerCellPressed:(BCPPhotoPickerViewAction)action {
    photoPickerAction = action;
    
    switch (action) {
        case BCPFileManager:{
            UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.image"] inMode:UIDocumentPickerModeImport];
            if (@available(iOS 13.0, *)) {
                picker.shouldShowFileExtensions = true;
            }
            picker.allowsMultipleSelection = false;
            picker.delegate = self;
            picker.modalPresentationStyle = UIModalPresentationFullScreen;
            [self presentViewController:picker animated:YES completion:NULL];
            
            break;
        }
            
        case BCPCamera: {
            if (action == BCPCamera && ![UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
                UIAlertController *myAlert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Device has no camera!" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction  * _Nonnull action) {
                    
                }];
                
                [myAlert addAction:okAction];
                [self presentViewController:myAlert animated:YES completion:nil];
                
            } else {
                [self askPermissionCamera:^(BOOL isPermitted) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        if (isPermitted) {
                            [self presentUIImagePickerController:action];
                        }
                        else {
                            NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
                            [self showAlertForPermission:[NSString stringWithFormat:@"%@ needs your permission to access the camera. Please change camera permission in Settings.", appName]];
                        }
                    });
                }];
            }
            break;
        }
            
        default: {
            [self presentUIImagePickerController:action];
            break;
        }
    }
}

- (void)presentUIImagePickerController:(BCPPhotoPickerViewAction)action {
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.sourceType = action == BCPCamera ? UIImagePickerControllerSourceTypeCamera : UIImagePickerControllerSourceTypePhotoLibrary;
    picker.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:picker animated:YES completion:NULL];
}

- (void)pickerDidSelectImage:(UIImage *)image {
    if ([_delegate respondsToSelector:@selector(bcPicker:didPickImage:)]) {
        [_delegate bcPicker:self didPickImage:image];
    }
}

//MARK:- UIDocumentPickerDelegate
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *imageURL = urls.firstObject;
    if (imageURL.isFileURL) {
        UIImage *image = [UIImage imageWithContentsOfFile:imageURL.path];
        if ([_delegate respondsToSelector:@selector(bcPicker:didPickImage:)]) {
            [_delegate bcPicker:self didPickImage:image];
        }
    }
}

//MARK:- UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    UIImage* originalImage = nil;
    originalImage = [info objectForKey:UIImagePickerControllerEditedImage];
    if(originalImage==nil)
    {
        originalImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    if(originalImage==nil)
    {
        originalImage = [info objectForKey:UIImagePickerControllerCropRect];
    }
    originalImage = [self normalizedImage:originalImage];
    [picker dismissViewControllerAnimated:true completion:^{
        if ([self->_delegate respondsToSelector:@selector(bcPicker:didPickImage:)]) {
            [self->_delegate bcPicker:self didPickImage:originalImage];
        }
    }];
}

- (UIImage *)normalizedImage:(UIImage *)image {
    if (image.imageOrientation == UIImageOrientationUp) return image;

    UIGraphicsBeginImageContextWithOptions(image.size, YES, image.scale);
    [image drawInRect:(CGRect){0, 0, image.size}];
    UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return normalizedImage;
}

//MARK:- AllowAccessDelegate
- (void)allowAccessButtonPressed {
    
    PHAuthorizationStatus phPermission;
    if (@available(iOS 14, *)) {
        phPermission = [PHPhotoLibrary authorizationStatusForAccessLevel:PHAccessLevelReadWrite];
    }
    else {
        phPermission = [PHPhotoLibrary authorizationStatus];
    }
    
    switch (phPermission) {
            
        case PHAuthorizationStatusNotDetermined: {
            [self askPermissionPhotoLibrary:^(BOOL isPermitted) {
                
                if (isPermitted) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        UICollectionViewCell *cell = [self->_collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
                        BCPPhotoPickerView *contentView = (BCPPhotoPickerView*)cell.contentView;
                        
                        if (self->_photoPickerAccessoryViewType == BCPPhotoAlbumView) {
                            [contentView loadAllAlbums];
                        }
                        else {
                            if (@available(iOS 14, *)) {
                                if ([PHPhotoLibrary authorizationStatusForAccessLevel:PHAccessLevelReadWrite] == PHAuthorizationStatusLimited) {
                                    [contentView loadAllSelectedPhotos];
                                }
                                else {
                                    [contentView loadAllPhotos];
                                }
                            } else {
                                [contentView loadAllPhotos];
                            }
                        }
                    });
                }
            }];
            break;
        }
            
        case PHAuthorizationStatusAuthorized:
        case PHAuthorizationStatusLimited: {
            NSLog(@"Photos authorized");
            break;
        }
            
        default: {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
            break;
        }
    }
}

//MARK:- Check Permission for media library
- (void)askPermissionPhotoLibrary:(void(^)(BOOL isPermitted))isPermitted
{
    if (@available(iOS 14, *)) {
        [PHPhotoLibrary requestAuthorizationForAccessLevel:PHAccessLevelReadWrite handler:^(PHAuthorizationStatus status) {
            
            [self checkPermission:status handler:^(BOOL isAuthorized) {
                isPermitted(isAuthorized);
            }];
        }];
    }
    else {
        
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status)
         {
            [self checkPermission:status handler:^(BOOL isAuthorized) {
                isPermitted(isAuthorized);
            }];
        }];
    }
}

- (void)checkPermission:(PHAuthorizationStatus)status handler:(void(^)(BOOL isAuthorized))isAuthorized {
    
    switch (status) {
            
        case PHAuthorizationStatusAuthorized:
        case PHAuthorizationStatusLimited: {
            NSLog(@"PHAuthorizationStatusAuthorized");
            isAuthorized(YES);
            break;
        }
        
        case PHAuthorizationStatusNotDetermined:
        case PHAuthorizationStatusRestricted:
        case PHAuthorizationStatusDenied: {
            isAuthorized(NO);
            break;
        }
            
        default: {
            isAuthorized(NO);
            break;
        }
    }
}

- (void) askPermissionCamera:(void(^)(BOOL isPermitted))isPermitted{
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(authStatus == AVAuthorizationStatusAuthorized) {
        isPermitted(YES);
    } else if(authStatus == AVAuthorizationStatusDenied){
        isPermitted(NO);
    } else if(authStatus == AVAuthorizationStatusRestricted){
        isPermitted(NO);
    } else if(authStatus == AVAuthorizationStatusNotDetermined){
        
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if(granted){
                isPermitted(YES);
            } else {
                isPermitted(NO);
            }
        }];
    } else {
        isPermitted(NO);
    }
}

//MARK:- - Alert for Permission
-(void) showAlertForPermission:(NSString *)permission {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Please check Permissions!" message:permission preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
        [alert dismissViewControllerAnimated:YES completion:nil];
    }];
    UIAlertAction *otherAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){
        [alert dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [alert addAction:otherAction];
    [alert addAction:settingsAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

//MARK:- ColorPickerViewDelegate
- (void)colorDidSelected:(BCPColorType)type hexCodes:(NSArray<NSString *> *)hexArray {
    if ([_delegate respondsToSelector:@selector(bcPicker:didPickColor:hexArray:)]) {
        [_delegate bcPicker:self didPickColor:type hexArray:hexArray];
    }
}

//MARK:- PixaBayPickerViewDelegate, UnsplashPickerViewDelegate
- (void)apiPhotoPickerDidPickImage:(UIImage *)image {
    if ([_delegate respondsToSelector:@selector(bcPicker:didPickImage:)]) {
        [_delegate bcPicker:self didPickImage:image];
    }
}

@end
