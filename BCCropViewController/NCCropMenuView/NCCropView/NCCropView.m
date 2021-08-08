//
//  NCCropView.m
//  NoCrop
//
//  Created by Brain Craft Ltd. on 4/13/21.
//

#import "NCCropView.h"
#import "NCCanvasCollectionViewCell.h"
@interface NCCropView(){
    __weak IBOutlet UICollectionView *cropRatioCollectionView;
    NSArray <NSDictionary*> *contents;
    NSDictionary <NSString*,NSArray*>  *dicForSocial;
    NSMutableDictionary *selectedInfoDict;
}

@end

@implementation NCCropView


- (void) awakeFromNib {
    [super awakeFromNib];
    selectedInfoDict = [[NSMutableDictionary alloc] init];
    [cropRatioCollectionView registerNib:[UINib nibWithNibName:@"NCCanvasCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"Cell"];
    NSString* canvasViewDataSourcePath = [[NSBundle mainBundle] pathForResource: @"NCCropRatio" ofType: @"plist"];
    dicForSocial = [NSDictionary dictionaryWithContentsOfFile: canvasViewDataSourcePath];
    contents = [dicForSocial objectForKey:@"Ratio"];
    [cropRatioCollectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
}

#pragma mark - CollectionView Delegates

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NCCanvasCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    cell.imageDictionary = (NSDictionary *)[contents objectAtIndex:indexPath.row];
    if (indexPath.item == contents.count-1) {
        cell.seperatorVisible = YES;
    }
    return cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return contents.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    NSDictionary *tempDic = [contents objectAtIndex:indexPath.row];
    UIImage *currentCellImage  = [UIImage imageNamed:tempDic[@"Unselected"]];
    CGFloat heightRatio = currentCellImage.size.height/currentCellImage.size.width;
    return CGSizeMake(currentCellImage.size.width * (SCREEN_WIDTH/414), currentCellImage.size.width * (SCREEN_WIDTH/414) * heightRatio);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == contents.count-1) {
        collectionView.tag = !collectionView.tag;
        NSString *keyName = collectionView.tag==0?@"Ratio":@"Social";
        contents = [dicForSocial objectForKey:keyName];
        [collectionView reloadData];
        if (collectionView.tag == [[selectedInfoDict objectForKey:@"Tag"] integerValue]) {
            [collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:[[selectedInfoDict objectForKey:@"Index"] integerValue] inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
        }
    }else{
        [selectedInfoDict setObject:[NSNumber numberWithInt:(int)collectionView.tag] forKey:@"Tag"];
        [selectedInfoDict setObject:[NSNumber numberWithInt:(int)indexPath.item] forKey:@"Index"];
        NSString *cropRatioString = [contents objectAtIndex:indexPath.item][@"ImageRatio"];
        if ([self.delgate respondsToSelector:@selector(cropView:didSelectRatio:)]) {
            [self.delgate cropView:self didSelectRatio:cropRatioString];
        }

    }
}


-(void)selectItemWithRatio:(NSString*)ratioStr{
    NSInteger index = -1;
    
    for (NSDictionary *dict in [dicForSocial objectForKey:@"Ratio"]) {
        if ([[dict objectForKey:@"ImageRatio"] isEqualToString:ratioStr]) {
            index = [[dicForSocial objectForKey:@"Ratio"] indexOfObject:dict];
            break;
        }
    }
    if (index<0) {
        for (NSDictionary *dict in [dicForSocial objectForKey:@"Social"]) {
            if ([[dict objectForKey:@"ImageRatio"] isEqualToString:ratioStr]) {
                index = [[dicForSocial objectForKey:@"Social"] indexOfObject:dict];
                break;
            }
        }
    }else{
        [cropRatioCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
        [cropRatioCollectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
        return;
    }
    if (index<0) {
        index = 0;
        contents = [dicForSocial objectForKey:@"Ratio"];
        [cropRatioCollectionView reloadData];
        [cropRatioCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
        [cropRatioCollectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
        return;
    }
    contents = [dicForSocial objectForKey:@"Social"];
    [cropRatioCollectionView reloadData];
    cropRatioCollectionView.tag = 1;
    [self->cropRatioCollectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
    [self->cropRatioCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];

}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
