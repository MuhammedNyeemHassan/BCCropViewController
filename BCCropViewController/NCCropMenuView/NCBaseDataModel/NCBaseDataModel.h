//
//  NCBaseDataModel.h
//  NoCrop
//
//  Created by Talat Mursalin on 20/5/21.
//

#import <Foundation/Foundation.h>
@import BCEffectLibrary;

NS_ASSUME_NONNULL_BEGIN

@interface NCBaseDataModel : NSObject

- (CGImageRef)outputCGImageFor:(CGImageRef)inputImage;
- (MTIImage*)outputMTImageFor:(MTIImage*)inputImage;
- (CGImageRef)outputCGImageForMTIImage:(MTIImage*)inputImage;

@end

NS_ASSUME_NONNULL_END
