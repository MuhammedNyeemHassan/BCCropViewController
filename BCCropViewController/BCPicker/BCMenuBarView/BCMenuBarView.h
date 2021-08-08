//
//  BCMenuView.h
//  BCPicker
//
//  Created by Somoy Das Gupta on 5/4/21.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class BCMenuBarView;

@protocol BCMenuBarViewDatasouce <NSObject>

- (NSArray<NSString *> *)menuTitlesForMenuView:(BCMenuBarView *)menuView;

@end

@protocol BCMenuBarViewDelegate <NSObject>

@optional
/**
 Menu index selection
 */
- (void)menuView:(BCMenuBarView *)menuView didSelectedAtIndex:(NSInteger)index;

@end

@interface BCMenuBarView : UIView

@property (weak, nonatomic) id<BCMenuBarViewDatasouce> dataSource;
@property (weak, nonatomic) id<BCMenuBarViewDelegate> delegate;

/**
 Menu default index
 */
@property (assign, nonatomic) NSUInteger defaultSelectedIndex;

/**
 Menu Bar BG Color
 */
@property (copy, nonatomic) UIColor *menuBarBGColor;

/**
 Menu cell BG Color & selected Color
 */
@property (copy, nonatomic) UIColor *menuCellBGColor;
@property (copy, nonatomic) UIColor *menuCellSelectedBGColor;

/**
 Menu title Color & title selected Color
 */
@property (copy, nonatomic) UIColor *menuSelectedTextColor;
@property (copy, nonatomic) UIColor *menuTextColor;

/**
 Menu indicator Color
 */
@property (copy, nonatomic) UIColor *menuIndicatorColor;

/**
 Menu Title Font
 */
@property (strong, nonatomic) UIFont *menuFont;

/**
 Menu Title Seletected Font
 */
@property (strong, nonatomic) UIFont *menuSelectedFont;

@end

NS_ASSUME_NONNULL_END
