//
//  BCPColorPickerView.m
//  BCPicker
//
//  Created by Somoy Das Gupta on 28/1/21.
//

#import "BCPColorPickerView.h"
#import "BCPColorPickerCell.h"

#define CELL_DEFAULT_WIDTH (51.0 * ([[UIScreen mainScreen] bounds].size.width / 414.0))
#define COLLECTION_DEFAULT_INTER_ITEM_SPACING (12.4 * ([[UIScreen mainScreen] bounds].size.width / 414.0))
#define COLLECTION_DEFAULT_LINE_SPACING (12.4 * ([[UIScreen mainScreen] bounds].size.width / 414.0))
#define COLLECTION_SECTION_LEFT_PADDING (20.0 * ([[UIScreen mainScreen] bounds].size.width / 414.0))
#define COLLECTION_SECTION_BOTTOM_PADDING (17.0 * ([[UIScreen mainScreen] bounds].size.width / 414.0))
#define COLLECTION_SECTION_HEADER_HEIGHT (45.0 * ([[UIScreen mainScreen] bounds].size.width / 414.0))
#define COLLECTION_SECTION_HEADER_TEXT_COLOR [UIColor colorWithRed:195.0/255.0f green:215.0/255.0f blue:230.0/255.0f alpha:1.0f]

@interface BCPColorPickerView(){
    NSArray *sectionNames;
    NSMutableArray *contents;
    UICollectionView *collectionView;
}

@end

@implementation BCPColorPickerView

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
}

- (void)prepareCollectionView {
    UICollectionViewFlowLayout* flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    
    collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:flowLayout];
    [self addSubview:collectionView];
    collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    collectionView.backgroundColor = UIColor.clearColor;
    
    [collectionView registerNib:[UINib nibWithNibName:@"BCPColorPickerCell" bundle:nil] forCellWithReuseIdentifier:@"BCPColorPickerCell"];
    [collectionView registerNib:[UINib nibWithNibName:@"BCPColorSectionReusableView" bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"BCPColorSectionReusableView"];
    
    collectionView.contentInset = UIEdgeInsetsMake(15.0, 0, 0, 0);
    
    collectionView.delegate = self;
    collectionView.dataSource = self;
}

- (void)setColorGroupTitles:(NSArray *)colorGroupTitles {
    _colorGroupTitles = colorGroupTitles;
    sectionNames = [NSArray arrayWithArray:_colorGroupTitles];
}

- (void)setColorPlistGroupArray:(NSArray<NSArray *> *)colorPlistGroupArray {
    _colorPlistGroupArray = colorPlistGroupArray;
    [self prepareData];
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)prepareData {
    contents = [[NSMutableArray<NSMutableArray*> alloc] init];
    
    for (NSArray *colorFiles in _colorPlistGroupArray) {
        
        NSMutableArray *contentGroup = [[NSMutableArray alloc] init];
        
        for (NSString *plistName in colorFiles) {
            NSArray *fileArray = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:plistName ofType:nil]];
                    [contentGroup addObjectsFromArray:fileArray];
        }
        
        [contents addObject:contentGroup];
    }
}

- (UIColor *)colorFromHexString:(NSString *)hexString {
    NSString *cleanString = [hexString stringByReplacingOccurrencesOfString:@"#" withString:@""];
    if([cleanString length] == 3) {
        cleanString = [NSString stringWithFormat:@"%@%@%@%@%@%@",
                       [cleanString substringWithRange:NSMakeRange(0, 1)],[cleanString substringWithRange:NSMakeRange(0, 1)],
                       [cleanString substringWithRange:NSMakeRange(1, 1)],[cleanString substringWithRange:NSMakeRange(1, 1)],
                       [cleanString substringWithRange:NSMakeRange(2, 1)],[cleanString substringWithRange:NSMakeRange(2, 1)]];
    }
    if([cleanString length] == 6) {
        cleanString = [cleanString stringByAppendingString:@"ff"];
    }
    
    unsigned int baseValue;
    [[NSScanner scannerWithString:cleanString] scanHexInt:&baseValue];
    
    float red   = ((baseValue >> 24) & 0xFF)/255.0f;
    float green = ((baseValue >> 16) & 0xFF)/255.0f;
    float blue  = ((baseValue >> 8)  & 0xFF)/255.0f;
    float alpha = ((baseValue >> 0)  & 0xFF)/255.0f;
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return CGSizeMake(CELL_DEFAULT_WIDTH, CELL_DEFAULT_WIDTH);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    return UIEdgeInsetsMake(0.0, COLLECTION_SECTION_LEFT_PADDING, COLLECTION_SECTION_BOTTOM_PADDING, COLLECTION_SECTION_LEFT_PADDING);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    
    return COLLECTION_DEFAULT_LINE_SPACING;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section{
    return COLLECTION_DEFAULT_INTER_ITEM_SPACING;
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    BCPColorPickerCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"BCPColorPickerCell" forIndexPath:indexPath];
    
    id cellData = contents[indexPath.section][indexPath.item];
    
    if ([cellData isKindOfClass:[NSArray class]]) {
        
        NSMutableArray *gradientColors = [[NSMutableArray alloc] init];
        [contents[indexPath.section][indexPath.item] enumerateObjectsUsingBlock:^(NSString * _Nonnull colorCode, NSUInteger idx, BOOL * _Nonnull stop) {
            [gradientColors addObject:[self colorFromHexString:colorCode].CGColor];
        }];
        cell.gradientColorArray = gradientColors;
    }
    else {
        NSString *hexString = contents[indexPath.section][indexPath.item];
        cell.cellColor = [self colorFromHexString:hexString];
    }
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
    UICollectionReusableView *view = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"BCPColorSectionReusableView" forIndexPath:indexPath];
    if (view) {
        UILabel *lbl = [view viewWithTag:999];
        
        if (lbl) {
            lbl.font = [UIFont fontWithName:@"SFProDisplay-Regular" size:14.0f];
            lbl.textColor = COLLECTION_SECTION_HEADER_TEXT_COLOR;
            lbl.text = sectionNames[indexPath.section];
        }
    }
    return view;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section{
    return CGSizeMake(collectionView.bounds.size.width, COLLECTION_SECTION_HEADER_HEIGHT);
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return ((NSArray*)contents[section]).count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return sectionNames.count;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (![_delegate respondsToSelector:@selector(colorDidSelected:hexCodes:)])
        return;
    
    switch (indexPath.section) {
        case BCPColor: {
            if (indexPath.item == 0) {
                [_delegate colorDidSelected:BCPColor hexCodes:@[]];
            }
            else {
                [_delegate colorDidSelected:BCPColor hexCodes:@[contents[indexPath.section][indexPath.item - 1]]];
            }
            break;
        }
        case BCPGradient: {
            [_delegate colorDidSelected:BCPGradient hexCodes:contents[indexPath.section][indexPath.item]];
            break;
        }
            
        default:
            break;
    }
}

@end
