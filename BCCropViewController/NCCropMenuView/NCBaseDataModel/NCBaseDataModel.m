//
//  NCBaseDataModel.m
//  NoCrop
//
//  Created by Talat Mursalin on 20/5/21.
//

#import "NCBaseDataModel.h"

@implementation NCBaseDataModel

- (CGImageRef)outputCGImageFor:(CGImageRef)inputImage {
  [NSException raise:@"Not Implemented Error" format:@"Subclass must override this method"];
  return nil;
}

- (MTIImage*)outputMTImageFor:(MTIImage*)inputImage {
  [NSException raise:@"Not Implemented Error" format:@"Subclass must override this method"];
  return nil;
}

- (CGImageRef)outputCGImageForMTIImage:(MTIImage*)inputImage {
  [NSException raise:@"Not Implemented Error" format:@"Subclass must override this method"];
  return nil;
}

@end
