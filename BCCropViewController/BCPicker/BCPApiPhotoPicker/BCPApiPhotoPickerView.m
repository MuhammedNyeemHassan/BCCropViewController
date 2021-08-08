//
//  BCPApiPhotoPickerView.m
//  BCPicker
//
//  Created by Somoy Das Gupta on 28/1/21.
//

#import "BCPApiPhotoPickerView.h"
#import "BCPApiPhotoPickerCell.h"
#import "USSearchService.h"
#import "CHTCollectionViewWaterfallLayout.h"
#import <SVPullToRefresh.h>
#import "USResponse.h"
#import <SDWebImageDownloader.h>
#import "ATPCustomProgressView.h"
#import "PBHitService.h"
#import "PBResponse.h"
#import "BCPicker.h"
#import "Reachability.h"

#define SEARCH_TEXT_FIELD_DEFAULT_CORNERRADIUS (6.0 * ([[UIScreen mainScreen] bounds].size.width / 414.0))
#define SEARCH_TEXT_DEFAULT_COLOR [UIColor colorWithRed:195.0/255.0f green:215.0/255.0f blue:230.0/255.0f alpha:1.0f]
#define SEARCH_TEXT_DEFAULT_FONT_SIZE (14.0 * ([[UIScreen mainScreen] bounds].size.width / 414.0))

@interface BCPApiPhotoPickerView () <CHTCollectionViewDelegateWaterfallLayout, UISearchBarDelegate, UICollectionViewDelegate,UICollectionViewDataSource> {
    
    Reachability *reachability;
}
@property (strong, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet CHTCollectionViewWaterfallLayout* layout;
@property (weak, nonatomic) IBOutlet UISearchBar* searchBar;
@property (weak, nonatomic) IBOutlet UIImageView *noPhotosFoundImageView;
@property (nonatomic, strong) NSObject *response;

@end

@implementation BCPApiPhotoPickerView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
*/
- (void)drawRect:(CGRect)rect {
    
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
        [self setupNotifications];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
        [self setupNotifications];
    }
    return self;
}

- (void)commonInit {
    self.backgroundColor = UIColor.clearColor;
    [[NSBundle mainBundle] loadNibNamed:@"BCPApiPhotoPickerView" owner:self options:nil];
    
    [self addSubview:self.contentView];
    self.contentView.frame = self.bounds;
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self prepareReachability];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self prepareSearchBar];
    [self prepareCollectionView];
}

- (void)removeFromSuperview {
    [super removeFromSuperview];
    USSearchService.sharedInstance.key = nil;
    USSearchService.sharedInstance.searchKeyword = @"";
    PBHitService.sharedInstance.key = nil;
    PBHitService.sharedInstance.searchKeyword = @"";
}

- (void)prepareSearchBar{
    _searchBar.delegate = self;
    
    UITextField *searchTextField;
    if (@available(iOS 13, *)) {
        searchTextField = _searchBar.searchTextField;
    } else {
        searchTextField = [_searchBar valueForKey:@"_searchField"];
    }
    searchTextField.font = [UIFont systemFontOfSize:SEARCH_TEXT_DEFAULT_FONT_SIZE];
    searchTextField.textColor = SEARCH_TEXT_DEFAULT_COLOR;
    
    [[UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UISearchBar class]]] setTitleTextAttributes:@{NSFontAttributeName : [UIFont systemFontOfSize:SEARCH_TEXT_DEFAULT_FONT_SIZE], NSForegroundColorAttributeName : SEARCH_TEXT_DEFAULT_COLOR} forState:UIControlStateNormal];
    
    dispatch_after(0.0, dispatch_get_main_queue(), ^{
        searchTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Search" attributes:@{ NSForegroundColorAttributeName : SEARCH_TEXT_DEFAULT_COLOR}];
    });
    
    UIImageView *leftImageView = (UIImageView*)searchTextField.leftView;
    if (leftImageView) {
        leftImageView.image = [[_searchBar imageForSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        leftImageView.tintColor = SEARCH_TEXT_DEFAULT_COLOR;
    }
    
    [_searchBar setSearchFieldBackgroundImage:[self getSearchTextFieldBackgroundImage:searchTextField.bounds.size color:_searchBar.barTintColor] forState:UIControlStateNormal];
}

- (UIImage*)getSearchTextFieldBackgroundImage:(CGSize)size color:(UIColor*)color {
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:SEARCH_TEXT_FIELD_DEFAULT_CORNERRADIUS];
    UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.mainScreen.scale);
    [color setFill];
    [path fill];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)prepareCollectionView {
    
    [_collectionView registerNib:[UINib nibWithNibName:@"BCPApiPhotoPickerCell" bundle:nil] forCellWithReuseIdentifier:@"BCPApiPhotoPickerCell"];
    
    _layout.columnCount = 2;
    _layout.itemRenderDirection = CHTCollectionViewWaterfallLayoutItemRenderDirectionShortestFirst;
    
    [_collectionView addInfiniteScrollingWithActionHandler:^{
        [self getNextPages];
    }];
}

- (void)prepareReachability {
    reachability = [Reachability reachabilityForInternetConnection];
    [reachability startNotifier];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityStatusDidChanged:) name:kReachabilityChangedNotification object:nil];
}

- (void)reachabilityStatusDidChanged:(NSNotification *)notification {
    
    if ([Reachability CheckInternetConnection]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reloadData];
        });
    }
}

//MARK:- Property Setters
- (void)setSearchTextFont:(UIFont *)searchTextFont {
    _searchTextFont = searchTextFont;
    
    UITextField *searchTextField;
    if (@available(iOS 13, *)) {
        searchTextField = _searchBar.searchTextField;
    } else {
        searchTextField = [_searchBar valueForKey:@"_searchField"];
    }
    searchTextField.font = _searchTextFont;
    
    [[UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UISearchBar class]]] setTitleTextAttributes:@{NSFontAttributeName : [UIFont systemFontOfSize:SEARCH_TEXT_DEFAULT_FONT_SIZE], NSForegroundColorAttributeName : SEARCH_TEXT_DEFAULT_COLOR} forState:UIControlStateNormal];
    
    dispatch_after(0.0, dispatch_get_main_queue(), ^{
        searchTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Search" attributes:@{ NSForegroundColorAttributeName : SEARCH_TEXT_DEFAULT_COLOR}];
    });
}

- (void)setApiKey:(NSString *)apiKey {
    _apiKey = apiKey;
    
    if (_type == BCPUnsplashAPI) {
        USSearchService.sharedInstance.key = _apiKey;
    }
    else if (_type == BCPPixabayAPI) {
        PBHitService.sharedInstance.key = _apiKey;
    }
    else if (_type == BCPGooglePhotosAPI) {
        
    }
    [self reloadData];
}

- (void)setPhotoTitleFont:(UIFont *)photoTitleFont {
    _photoTitleFont = photoTitleFont;
    
    [_collectionView reloadData];
}

//MARK:- API call
- (void)reloadData {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        if (self.type == BCPUnsplashAPI)
        {
            [[[USSearchService sharedInstance] getUSResults]
             subscribeNext:^(USResponse *response) {
                self->_response = response;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self->_collectionView reloadData];
                    [self->_collectionView.pullToRefreshView stopAnimating];
                    [self->_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
                    self->_noPhotosFoundImageView.hidden = response.results.count;
                });
            }
             error:^(NSError *error) {
                NSLog(@"error : %@",error);
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [self->_collectionView.pullToRefreshView stopAnimating];
                    
                    if (error.code == NSURLErrorNotConnectedToInternet) {
                        UIAlertController *noInternetAlert = [UIAlertController alertControllerWithTitle:@"No Internet!" message:@"Please connect to internet to download image." preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleCancel handler:nil];
                        
                        [noInternetAlert addAction:ok];
                        [((BCPicker*)self->_delegate) presentViewController:noInternetAlert animated:true completion:nil];
                    }
                });
            }];
        }
        else if (self.type == BCPPixabayAPI)
        {
            [[[PBHitService sharedInstance] getPBHits]
             subscribeNext:^(PBResponse *response) {
                self->_response = response;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self->_collectionView reloadData];
                    [self->_collectionView.pullToRefreshView stopAnimating];
                    [self->_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
                    self->_noPhotosFoundImageView.hidden = response.hits.count;
                });
            }
             error:^(NSError *error) {
                NSLog(@"error : %@",error);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self->_collectionView.pullToRefreshView stopAnimating];
                    
                    if (error.code == NSURLErrorNotConnectedToInternet) {
                        UIAlertController *noInternetAlert = [UIAlertController alertControllerWithTitle:@"No Internet!" message:@"Please connect to internet to download image." preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleCancel handler:nil];
                        
                        [noInternetAlert addAction:ok];
                        [((BCPicker*)self->_delegate) presentViewController:noInternetAlert animated:true completion:nil];
                    }
                });
            }];
        }
        else if (self.type == BCPGooglePhotosAPI) {
            
        }
    });
}

- (void)getNextPages {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        if (self.type == BCPUnsplashAPI)
        {
            [[[USSearchService sharedInstance] getUSResultsFromNextPage]
             subscribeNext:^(NSMutableArray<USResult *> * results) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (results.count) {
                        USResponse *usResponse = (USResponse*)self->_response;
                        [usResponse.results addObjectsFromArray:results];
                        [self->_collectionView reloadData];
                    }
                    [self->_collectionView.infiniteScrollingView stopAnimating];
                });
            } error:^(NSError *error) {
                NSLog(@"error : %@",error);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self->_collectionView.pullToRefreshView stopAnimating];
                });
            }];
        }
        else if (self.type == BCPPixabayAPI)
        {
            [[[PBHitService sharedInstance] getPBHitsFromNextPage]
             subscribeNext:^(NSMutableArray<PBHit *> * hits) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (hits.count) {
                        PBResponse *pbResponse = (PBResponse*)self->_response;
                        [pbResponse.hits addObjectsFromArray:hits];
                        [self->_collectionView reloadData];
                    }
                    [self->_collectionView.infiniteScrollingView stopAnimating];
                });
            } error:^(NSError *error) {
                NSLog(@"error : %@",error);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self->_collectionView.pullToRefreshView stopAnimating];
                });
            }];
        }
        else if (self.type == BCPGooglePhotosAPI) {
            
        }
    });
}

//MARK:- Keyboard Notifications
- (void)setupNotifications {
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardWillShowNotification:) name:UIKeyboardWillShowNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardWillHideNotification:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShowNotification:(NSNotification*)notification {
    CGSize keyboardSize = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    NSTimeInterval duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    CGFloat bottomInset = keyboardSize.height - self.safeAreaInsets.bottom;
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0, 0, 0 + bottomInset, 0);
    
    [UIView animateWithDuration:duration animations:^{
        self.collectionView.contentInset = contentInsets;
        self.collectionView.scrollIndicatorInsets = contentInsets;
    } completion:nil];
}

- (void)keyboardWillHideNotification:(NSNotification*)notification {
    NSTimeInterval duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:duration animations:^{
        self.collectionView.contentInset = UIEdgeInsetsZero;
        self.collectionView.scrollIndicatorInsets = UIEdgeInsetsZero;
    } completion:nil];
}

//MARK:- UICollectionViewDelegate, UICollectionViewDataSource
- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    BCPApiPhotoPickerCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"BCPApiPhotoPickerCell" forIndexPath:indexPath];
    
    cell.cellTitleFont = _photoTitleFont;
    
    if (self.type == BCPUnsplashAPI)
    {
        USResult *cellResult = ((USResponse*)_response).results[indexPath.item];
        [cell configureWithResult:cellResult];
    }
    else if (self.type == BCPPixabayAPI)
    {
        PBHit *cellHit = ((PBResponse*)_response).hits[indexPath.item];
        [cell configureWithHit:cellHit];
    }
    else if (self.type == BCPGooglePhotosAPI) {
        
    }
    
    return cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    if (self.type == BCPUnsplashAPI)
    {
        return ((USResponse*)_response).results.count;
    }
    else if (self.type == BCPPixabayAPI)
    {
        return ((PBResponse*)_response).hits.count;
    }
    else if (self.type == BCPGooglePhotosAPI) {
        
    }
    
    return 0;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.type == BCPUnsplashAPI)
    {
        USResult *selectedResult = ((USResponse*)_response).results[indexPath.item];
        return CGSizeMake(selectedResult.width.floatValue, selectedResult.height.floatValue);
    }
    else if (self.type == BCPPixabayAPI)
    {
        PBHit *selectedHit = ((PBResponse*)_response).hits[indexPath.item];
        return CGSizeMake(selectedHit.previewWidth.floatValue, selectedHit.previewHeight.floatValue);
    }
    else if (self.type == BCPGooglePhotosAPI) {
        
    }
    
    return CGSizeZero;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    static BOOL isDownloading = NO;
    if (!isDownloading) {
        isDownloading = YES;
        
        [self endEditing:true];
        
        NSString *imageURL = @"";
        
        if (self.type == BCPUnsplashAPI)
        {
            USResult *selectedResult = ((USResponse*)_response).results[indexPath.item];
            imageURL = selectedResult.urls.regular;
        }
        else if (self.type == BCPPixabayAPI)
        {
            PBHit *cellHit = ((PBResponse*)_response).hits[indexPath.item];
            imageURL = (cellHit.fullHDURL ? cellHit.fullHDURL : (cellHit.imageURL ? cellHit.imageURL : cellHit.largeImageURL));
        }
        else if (self.type == BCPGooglePhotosAPI) {
            
        }
        
        [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:[NSURL URLWithString:imageURL] options:SDWebImageDownloaderHighPriority progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
            CGFloat fraction = (1.0 * receivedSize) / (1.0 * expectedSize);
            if (expectedSize > 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [ATPCustomProgressView showLoadingViewWithText:[NSString stringWithFormat:@"Downloading! Please don’t close or\n Lock your device."] withProgress: fraction withCancelationBlock:^(BOOL cancelled) {
                        if (cancelled) {
                            [[SDWebImageDownloader sharedDownloader] cancelAllDownloads];
                            isDownloading = NO;
                        }
                    }];
                });
            }
        } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
            if (finished) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIImage *downloadedImage = image;
                    if ([self->_delegate respondsToSelector:@selector(apiPhotoPickerDidPickImage:)] && image) {
                        [self->_delegate apiPhotoPickerDidPickImage:downloadedImage];
                    }
                    [ATPCustomProgressView removeLoadingView];
                    isDownloading = NO;
                });
            }
            
            if (error) {
                if (error.code == NSURLErrorNotConnectedToInternet) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIAlertController *noInternetAlert = [UIAlertController alertControllerWithTitle:@"No Internet!" message:@"Please connect to internet to download image." preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleCancel handler:nil];
                        
                        [noInternetAlert addAction:ok];
                        [((BCPicker*)self->_delegate) presentViewController:noInternetAlert animated:true completion:nil];
                    });
                }
                isDownloading = NO;
            }
        }];
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(5.0, 14.0, 10.0, 14.0);
}

//MARK:- ScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [_searchBar resignFirstResponder];
}

//MARK:- UISearchBarDelegate
- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:NO animated:YES];
    
    return true;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText  {
    if (self.type == BCPUnsplashAPI) {
        USSearchService.sharedInstance.searchKeyword = searchText;
    }
    else if (self.type == BCPPixabayAPI) {
        PBHitService.sharedInstance.searchKeyword = searchText;
    }
    else if (self.type == BCPGooglePhotosAPI) {
        
    }
    
    if (!searchText.length) {
        [self reloadData];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self endEditing:true];
    [self reloadData];
}

@end
