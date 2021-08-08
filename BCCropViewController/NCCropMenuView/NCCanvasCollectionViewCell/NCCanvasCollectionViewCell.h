//
//  NCCanvasCollectionViewCell.h
//  NoCrop
//
//  Created by Kazi Muhammad Tawsif Jamil on 3/4/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NCCanvasCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *canvasCollectionViewCellImageView;
@property (strong, nonatomic) NSDictionary<NSString*, NSString*> *imageDictionary;
@property (weak, nonatomic) IBOutlet UIView *seperator;
@property (nonatomic,assign) BOOL seperatorVisible;
@end

NS_ASSUME_NONNULL_END
