//
//  NCCropDataModel.h
//  NoCrop
//
//  Created by Brain Craft Ltd. on 6/2/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NCCropDataModel : NCBaseDataModel
@property (nonatomic,strong) NSString *cropRatio;
@property (nonatomic,strong) NSString *cropContentOffset;
@property (nonatomic,strong) NSString *cropScrollZoomRect;
@property (nonatomic,assign) BOOL flipH;
@property (nonatomic,assign) BOOL flipV;
@property (nonatomic,assign) CGFloat rotationValue;
@property (nonatomic,assign) CGFloat skewHValue;
@property (nonatomic,assign) CGFloat skewVValue;
@property (nonatomic,assign) CGFloat zoomScale;
@property (nonatomic,strong) NSString* lastCropViewSize;

-(id)initWithDictionary:(NSDictionary*)cropInfoDict;


@end

NS_ASSUME_NONNULL_END
