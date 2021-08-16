//
//  NCCropDataModel.h
//  NoCrop
//
//  Created by Brain Craft Ltd. on 6/2/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NCCropDataModel : NCBaseDataModel
@property (nonatomic,assign) BOOL flipH;
@property (nonatomic,assign) BOOL flipV;
@property (nonatomic,assign) CGFloat rotationAngle;
@property (nonatomic,assign) CGFloat zoomScale;
@property (nonatomic,assign) CGSize cropSize;
@property (nonatomic,assign) CGSize imageLayerSize;
@property (nonatomic,assign) CGPoint imageTopLeftPoint;
@property (nonatomic,assign) CGPoint imageTopRightPoint;
@property (nonatomic,assign) CGPoint imageBottomRightPoint;
@property (nonatomic,assign) CGPoint imageBottomLeftPoint;
@property (nonatomic,assign) CGPoint imageTranslationPoint;

-(id)initWithDictionary:(NSDictionary*)cropInfoDict;
-(UIImage*)croppedImage:(UIImage*)inputImage;


@end

NS_ASSUME_NONNULL_END
