//
//  BCMenuBarView.m
//  BCPicker
//
//  Created by Somoy Das Gupta on 5/4/21.
//

#import "BCMenuBarView.h"

#define MENU_DEFAULT_BG_COLOR [UIColor colorWithRed:24.0/255.0f green:25.0/255.0f blue:28.0/255.0f alpha:1.0f]

#define MENU_DEFAULT_TEXT_COLOR [UIColor colorWithRed:195.0/255.0f green:215.0/255.0f blue:230.0/255.0f alpha:1.0f]
#define MENU_DEFAULT_TEXT_SELECTED_COLOR [UIColor colorWithRed:69.0/255.0f green:216.0/255.0f blue:252.0/255.0f alpha:1.0f]

#define MENU_INDICATOR_DEFAULT_HEIGHT (2.0 * ([[UIScreen mainScreen] bounds].size.width / 414.0))
#define MENU_INDICATOR_DEFAULT_BG_COLOR [UIColor colorWithRed:69.0/255.0f green:216.0/255.0f blue:252.0/255.0f alpha:1.0f]

#define MENU_BOTTOM_BORDER_COLOR [UIColor colorWithRed:13.0/255.0f green:14.0/255.0f blue:15.0/255.0f alpha:1.0f]

#define MENU_TITLE_DEFAULT_FONT_SIZE (14.0 * ([[UIScreen mainScreen] bounds].size.width / 414.0))
#define MENU_TITLE_DEFAULT_TEXT_PADDING (25.0 * ([[UIScreen mainScreen] bounds].size.width / 414.0))

//MARK:-
//MARK:- BCMenuCollectionViewCell
@interface BCMenuCollectionViewCell : UICollectionViewCell

@property (copy, nonatomic) NSString *menuTitle;

@property (copy, nonatomic) UIColor *cellBGColor;
@property (copy, nonatomic) UIColor *cellSelectedBGColor;

@property (copy, nonatomic) UIColor *titleSelectedTextColor;
@property (copy, nonatomic) UIColor *titleTextColor;

@property (copy, nonatomic) UIColor *indicatorBGColor;

@property (strong, nonatomic) UIFont *titleFont;
@property (strong, nonatomic) UIFont *titleSelectedFont;

@end

@interface BCMenuCollectionViewCell ()

@property (strong, nonatomic) UILabel *menuTitleLabel;
@property (strong, nonatomic) UIView *menuIndicatorView;
@end

@implementation BCMenuCollectionViewCell

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

- (void)awakeFromNib {
    [super awakeFromNib];
}

//MARK:- Prepare
- (void)commonInit {
    
    self.backgroundColor = UIColor.clearColor;
    self.contentView.backgroundColor = UIColor.clearColor;
    self.clipsToBounds = true;
    
    _cellBGColor = UIColor.clearColor;
    _cellSelectedBGColor = UIColor.clearColor;
    
    _titleTextColor = MENU_DEFAULT_TEXT_COLOR;
    _titleSelectedTextColor = MENU_DEFAULT_TEXT_SELECTED_COLOR;
    _indicatorBGColor = MENU_INDICATOR_DEFAULT_BG_COLOR;
    
    _titleFont = [UIFont systemFontOfSize:MENU_TITLE_DEFAULT_FONT_SIZE];
    _titleSelectedFont = [UIFont systemFontOfSize:MENU_TITLE_DEFAULT_FONT_SIZE];
    
    [self prepareMenuTitleLabel];
    [self prepareMenuIndicatorView];
    [self prepareConstraints];
}

- (void)prepareMenuTitleLabel {
    _menuTitleLabel = [[UILabel alloc] init];
    _menuTitleLabel.textColor = _titleTextColor;
    _menuTitleLabel.frame = self.bounds;
    _menuTitleLabel.textAlignment = NSTextAlignmentCenter;
    _menuTitleLabel.backgroundColor = UIColor.clearColor;
    
    _menuTitleLabel.font = _titleFont;
    
    [self addSubview:_menuTitleLabel];
}

- (void)prepareMenuIndicatorView {
    _menuIndicatorView = [[UIView alloc] initWithFrame:CGRectMake(0.0, (self.bounds.size.height - MENU_INDICATOR_DEFAULT_HEIGHT), self.bounds.size.width, MENU_INDICATOR_DEFAULT_HEIGHT)];
    _menuIndicatorView.backgroundColor = _indicatorBGColor;
    _menuIndicatorView.hidden = true;
    
    [self addSubview:_menuIndicatorView];
}

- (void)prepareConstraints {
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(_menuTitleLabel, _menuIndicatorView);
    
    [self addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_menuTitleLabel]-0-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:viewsDictionary]];
    [self addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_menuIndicatorView]-0-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:viewsDictionary]];
    [self addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[_menuTitleLabel]-0-|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:viewsDictionary]];
    [self addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[_menuIndicatorView(%f)]-0-|", MENU_INDICATOR_DEFAULT_HEIGHT] options:NSLayoutFormatAlignAllCenterX metrics:nil views:viewsDictionary]];
}

//MARK:- Select
- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    
    self.contentView.backgroundColor = self.isSelected ? _cellSelectedBGColor : _cellBGColor;
    _menuTitleLabel.textColor = self.isSelected ? _titleSelectedTextColor : _titleTextColor;
    _menuTitleLabel.font = self.isSelected ? _titleSelectedFont : _titleFont;
    _menuIndicatorView.hidden = !self.selected;
}

//MARK:- Property Setter
- (void)setMenuTitle:(NSString *)menuTitle {
    _menuTitle = menuTitle;
    _menuTitleLabel.text = _menuTitle;
}

- (void)setCellBGColor:(UIColor *)cellBGColor {
    _cellBGColor = cellBGColor;
    self.contentView.backgroundColor = _cellBGColor;
}

- (void)setCellSelectedBGColor:(UIColor *)cellSelectedBGColor {
    _cellSelectedBGColor = cellSelectedBGColor;
}

- (void)setTitleTextColor:(UIColor *)titleTextColor {
    _titleTextColor = titleTextColor;
    _menuTitleLabel.textColor = _titleTextColor;
}

- (void)setTitleSelectedTextColor:(UIColor *)titleSelectedTextColor {
    _titleSelectedTextColor = titleSelectedTextColor;
}

- (void)setIndicatorBGColor:(UIColor *)indicatorBGColor {
    _indicatorBGColor = indicatorBGColor;
    _menuIndicatorView.backgroundColor = _indicatorBGColor;
}

- (void)setTitleFont:(UIFont *)titleFont {
    _titleFont = titleFont;
    [self setTitleSelectedFont:_titleFont];
    _menuTitleLabel.font = _titleFont;
}

- (void)setTitleSelectedFont:(UIFont *)titleSelectedFont {
    _titleSelectedFont = titleSelectedFont;
}
@end


//MARK:-
//MARK:- BCMenuBarView
@interface BCMenuBarView ()<UICollectionViewDelegateFlowLayout, UICollectionViewDataSource>

@property (strong, nonatomic) UICollectionView *menuCollectionView;
@property (strong, nonatomic) UIView *menuBottomBorderView;

@property (strong, nonatomic) NSArray<NSString*> *titleArray;
@property (strong, nonatomic) NSArray<NSValue*> *sizeArray;

@property (nonatomic) CGFloat titleHotizontalInset;

@end

@implementation BCMenuBarView

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
    self.backgroundColor = MENU_DEFAULT_BG_COLOR;
    _titleHotizontalInset = MENU_TITLE_DEFAULT_TEXT_PADDING;
    _defaultSelectedIndex = 0;
    
    [self prepareMenuBottomBorderView];
    [self prepareCollectionView];
    [self prepareConstraints];
}

//MARK:- Prepare
- (void)prepareCollectionView {
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    _menuCollectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:flowLayout];
    _menuCollectionView.backgroundColor = UIColor.clearColor;
    _menuCollectionView.showsHorizontalScrollIndicator = NO;
    [self addSubview:_menuCollectionView];
    
    _menuCollectionView.delegate = self;
    _menuCollectionView.dataSource = self;
    
    [_menuCollectionView registerClass:[BCMenuCollectionViewCell class] forCellWithReuseIdentifier:@"BCMenuCollectionViewCell"];
}

- (void)prepareMenuBottomBorderView {
    _menuBottomBorderView = [[UIView alloc] initWithFrame:CGRectMake(0, self.bounds.size.height - MENU_INDICATOR_DEFAULT_HEIGHT, self.bounds.size.width, MENU_INDICATOR_DEFAULT_HEIGHT)];
    _menuBottomBorderView.backgroundColor = MENU_BOTTOM_BORDER_COLOR;
    [self addSubview:_menuBottomBorderView];
}

- (void)prepareConstraints {
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(_menuCollectionView, _menuBottomBorderView);
    
    _menuCollectionView.translatesAutoresizingMaskIntoConstraints = NO;
    _menuBottomBorderView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_menuCollectionView]-0-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:viewsDictionary]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[_menuCollectionView]-0-|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:viewsDictionary]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_menuBottomBorderView]-0-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:viewsDictionary]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[_menuBottomBorderView(%f)]-0-|", MENU_INDICATOR_DEFAULT_HEIGHT] options:NSLayoutFormatAlignAllCenterX metrics:nil views:viewsDictionary]];
}

- (void)prepareTitleHorizontalPadding {
    
    if (_titleArray && _titleArray.count < 5) {
        
        CGFloat widthSum = 0.0;
        for (NSString *title in _titleArray) {
            CGSize textSize = [title sizeWithAttributes:@{NSFontAttributeName: _menuFont ? _menuFont : [UIFont systemFontOfSize:MENU_TITLE_DEFAULT_FONT_SIZE]}];
            
            widthSum += textSize.width;;
        }
        
        if (widthSum > UIScreen.mainScreen.bounds.size.width) {
            _titleHotizontalInset = MENU_TITLE_DEFAULT_TEXT_PADDING;
        }
        else {
            _titleHotizontalInset = (UIScreen.mainScreen.bounds.size.width - widthSum)/(_titleArray.count * 2.0);
        }
    }
    else {
        _titleHotizontalInset = MENU_TITLE_DEFAULT_TEXT_PADDING;
    }
}

//MARK:- Property Setters
- (void)setDataSource:(id<BCMenuBarViewDatasouce>)dataSource {
    _dataSource = dataSource;
    if (_dataSource) {
        
        if ([_dataSource respondsToSelector:@selector(menuTitlesForMenuView:)]) {
            _titleArray = [_dataSource menuTitlesForMenuView:self];
            [self prepareTitleHorizontalPadding];
        }
    }
    [_menuCollectionView reloadData];
    [_menuCollectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:_defaultSelectedIndex inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
}

- (void)setDefaultSelectedIndex:(NSUInteger)defaultSelectedIndex {
    _defaultSelectedIndex = defaultSelectedIndex;
    [_menuCollectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:_defaultSelectedIndex inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
}

- (void)setMenuBarBGColor:(UIColor *)menuBarBGColor {
    _menuBarBGColor = menuBarBGColor;
    self.backgroundColor = _menuBarBGColor;
}

- (void)setMenuCellBGColor:(UIColor *)menuCellBGColor{
    _menuCellBGColor = menuCellBGColor;
    [_menuCollectionView reloadData];
}

- (void)setMenuCellSelectedBGColor:(UIColor *)menuCellSelectedBGColor {
    _menuCellSelectedBGColor = menuCellSelectedBGColor;
    [_menuCollectionView reloadData];
}

- (void)setMenuTextColor:(UIColor *)menuTextColor {
    _menuTextColor = menuTextColor;
    [_menuCollectionView reloadData];
}

- (void)setMenuIndicatorColor:(UIColor *)menuIndicatorColor {
    _menuIndicatorColor = menuIndicatorColor;
    [_menuCollectionView reloadData];
}

- (void)setMenuFont:(UIFont *)menuFont {
    _menuFont = menuFont;
    [self setMenuSelectedFont:_menuFont];
    [_menuCollectionView reloadData];
}

- (void)setMenuSelectedFont:(UIFont *)menuSelectedFont {
    _menuSelectedFont = menuSelectedFont;
    [_menuCollectionView reloadData];
}

//MARK:- MenuCollectionView Delegate & DataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return _titleArray.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height = collectionView.bounds.size.height;
    
    NSString *title = _titleArray[indexPath.item];
    CGSize textSize = [title sizeWithAttributes:@{NSFontAttributeName: _menuFont ? _menuFont : [UIFont systemFontOfSize:MENU_TITLE_DEFAULT_FONT_SIZE]}];
    
    CGFloat width = textSize.width + 2.0 * _titleHotizontalInset;
    
    return CGSizeMake(width, height);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0.0;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BCMenuCollectionViewCell *cell = (BCMenuCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"BCMenuCollectionViewCell" forIndexPath:indexPath];
    
    cell.menuTitle = _titleArray[indexPath.item];
    
    if (_menuCellBGColor)
        cell.cellBGColor = self.menuCellBGColor;
    
    if (_menuCellSelectedBGColor)
        cell.cellSelectedBGColor = self.menuCellSelectedBGColor;
    
    if (_menuTextColor)
        cell.titleTextColor = self.menuTextColor;
    
    if (_menuSelectedTextColor)
        cell.titleSelectedTextColor = self.menuSelectedTextColor;
    
    if (_menuIndicatorColor)
        cell.indicatorBGColor = self.menuIndicatorColor;
    
    if (_menuFont)
        cell.titleFont = _menuFont;
    
    if (_menuSelectedFont)
        cell.titleSelectedFont = _menuSelectedFont;
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    _defaultSelectedIndex = indexPath.item;
    [collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    if (_delegate) {
        if ([_delegate respondsToSelector:@selector(menuView:didSelectedAtIndex:)]) {
            [_delegate menuView:self didSelectedAtIndex:indexPath.item];
        }
    }
}

@end
