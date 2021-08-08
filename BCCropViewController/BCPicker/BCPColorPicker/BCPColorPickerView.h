//
//  BCPColorPickerView.h
//  BCPicker
//
//  Created by Somoy Das Gupta on 28/1/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    BCPColor,
    BCPGradient
} BCPColorType;

@protocol BCPColorPickerViewDelegate <NSObject>

- (void)colorDidSelected:(BCPColorType)type hexCodes:(NSArray<NSString*>*)hexArray;

@end

@interface BCPColorPickerView : UIView <UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>
@property (weak, nonatomic) id<BCPColorPickerViewDelegate> delegate;

@property (copy, nonatomic) NSArray * colorGroupTitles;
@property (copy, nonatomic) NSArray<NSArray*>* colorPlistGroupArray;
@end

NS_ASSUME_NONNULL_END
