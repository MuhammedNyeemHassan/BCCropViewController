//
//  NCCropDataModel.m
//  NoCrop
//
//  Created by Brain Craft Ltd. on 6/2/21.
//

#import "NCCropDataModel.h"

@implementation NCCropDataModel
-(id)initWithDictionary:(NSDictionary*)cropInfoDict{
    self = [super init];
    if (self) {
        self.flipH = [[cropInfoDict objectForKey:@"flipH"] boolValue];
        self.flipV = [[cropInfoDict objectForKey:@"flipV"] boolValue];
        self.rotationAngle = [[cropInfoDict objectForKey:@"rotationAngle"] floatValue];
        self.zoomScale = [[cropInfoDict objectForKey:@"zoomScale"] floatValue];
        self.cropSize = CGSizeFromString([cropInfoDict objectForKey:@"cropSize"]);
        self.imageLayerSize = CGSizeFromString([cropInfoDict objectForKey:@"imageLayerSize"]);
        self.imageTopLeftPoint = CGPointFromString([cropInfoDict objectForKey:@"imageTopLeftPoint"]);
        self.imageTopRightPoint = CGPointFromString([cropInfoDict objectForKey:@"imageTopRightPoint"]);
        self.imageBottomLeftPoint = CGPointFromString([cropInfoDict objectForKey:@"imageBottomLeftPoint"]);
        self.imageBottomRightPoint = CGPointFromString([cropInfoDict objectForKey:@"imageBottomRightPoint"]);
        self.imageTranslationPoint = CGPointFromString([cropInfoDict objectForKey:@"imageTranslationPoint"]);

    }
    return self;
}


-(UIImage*)croppedImage:(UIImage*)inputImage{
    CIContext *context = [[CIContext alloc] init];
    CIImage *filterImage = [[CIImage alloc] initWithImage:inputImage];
    if (self.flipH) {
        filterImage = [filterImage imageByApplyingTransform:CGAffineTransformScale(CGAffineTransformIdentity, -1, 1)];
    }
    if (self.flipV) {
        filterImage = [filterImage imageByApplyingTransform:CGAffineTransformScale(CGAffineTransformIdentity, 1, -1)];
        
    }
    CIFilter *perspectiveFilter = [CIFilter filterWithName:@"CIPerspectiveTransform"];
    [perspectiveFilter setValue:filterImage forKey:@"inputImage"];
    CIVector *vectorTL = [CIVector vectorWithCGPoint:self.imageTopLeftPoint];
    CIVector *vectorTR = [CIVector vectorWithCGPoint:self.imageTopRightPoint];
    CIVector *vectorBR = [CIVector vectorWithCGPoint:self.imageBottomRightPoint];
    CIVector *vectorBL = [CIVector vectorWithCGPoint:self.imageBottomLeftPoint];
    [perspectiveFilter setValue:vectorTL forKey:@"inputTopLeft"];
    [perspectiveFilter setValue:vectorTR forKey:@"inputTopRight"];
    [perspectiveFilter setValue:vectorBR forKey:@"inputBottomRight"];
    [perspectiveFilter setValue:vectorBL forKey:@"inputBottomLeft"];
    filterImage = [perspectiveFilter outputImage];
    
    CGImageRef cgImage = [context createCGImage:filterImage fromRect:filterImage.extent];
    UIImage *image = [UIImage imageWithCGImage:cgImage scale:inputImage.scale orientation:inputImage.imageOrientation];
    CGImageRelease(cgImage);
    UIImage *croppedImage = [self cropResultWithImage:image];
    return croppedImage;
}

-(UIImage *)cropResultWithImage:(UIImage *)image
{
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    // translate
    CGPoint translation  = self.imageTranslationPoint;
    transform = CGAffineTransformTranslate(transform, translation.x, translation.y);
    
    // rotate
    transform = CGAffineTransformRotate(transform, self.rotationAngle);

    UIImage *newImage = [self imageWithFixedOrientation:image];
    newImage = [self imageWithTransform:transform sourceImage:newImage zoomScale:self.zoomScale cropSize:self.cropSize imageViewSize:self.imageLayerSize];
    return newImage;
}

-(UIImage *)imageWithFixedOrientation:(UIImage *)img{
    
    CGImageRef cgImage = [img CGImage];
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(cgImage);
    
    if (cgImage == nil || colorSpace == nil) {
        return nil;
    }
    
    if (img.imageOrientation == UIImageOrientationUp) {
        return img;
    }
    
    CGFloat width  = CGImageGetWidth(cgImage);
    CGFloat height = CGImageGetHeight(cgImage);
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (img.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:{
            transform = CGAffineTransformTranslate(transform, width, height);
            transform = CGAffineTransformRotate(transform, M_PI);
        }break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:{
            transform = CGAffineTransformTranslate(transform, width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
        }break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:{
            transform = CGAffineTransformTranslate(transform, 0, height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
        }break;
            
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }
    
    switch (img.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:{
            transform = CGAffineTransformTranslate(transform, width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
        }break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:{
            transform = CGAffineTransformTranslate(transform, height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
        }break;
            
        default:
            break;
    }
    
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 width,
                                                 height,
                                                 CGImageGetBitsPerComponent(cgImage),
                                                 0,
                                                 colorSpace,
                                                 CGImageGetBitmapInfo(cgImage)
                                                 );
    if (context == nil) {
        return nil;
    }
    CGColorSpaceRelease(colorSpace);
    CGContextConcatCTM(context, transform);
    
    switch (img.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:{
            CGContextDrawImage(context, CGRectMake(0 , 0, height, width), cgImage);
        }break;
            
        default:
            CGContextDrawImage(context, CGRectMake(0 , 0, width, height), cgImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef newCGImg = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    UIImage *newImage = [[UIImage alloc] initWithCGImage:newCGImg];
    CGImageRelease(newCGImg);
    return newImage;
}

-(UIImage *)imageWithTransform:(CGAffineTransform)transform
                   sourceImage:(UIImage *)sourceImage
                     zoomScale:(CGFloat) zoomScale
                      cropSize:(CGSize) cropSize
                 imageViewSize:(CGSize) imageViewSize
{
    CGFloat expectedWidth = floor((sourceImage.size.width / imageViewSize.width) * cropSize.width) / zoomScale;
    CGFloat expectedHeight = floor((sourceImage.size.height / imageViewSize.height) * cropSize.height) / zoomScale;
    CGSize outputSize = CGSizeMake(expectedWidth, expectedHeight);
    int bitmapBytesPerRow = 0;
    
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 (int)outputSize.width,
                                                 (int)outputSize.height,
                                                 CGImageGetBitsPerComponent(sourceImage.CGImage),
                                                 bitmapBytesPerRow,
                                                 CGImageGetColorSpace(sourceImage.CGImage),
                                                 CGImageGetBitmapInfo(sourceImage.CGImage)
                                                 );
    if (context == nil) {
        return nil;
    }
    
    CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, outputSize.width, outputSize.height));
    
    
    CGAffineTransform uiCoords = CGAffineTransformMakeScale(outputSize.width / cropSize.width,
                                                            outputSize.height / cropSize.height);
    uiCoords = CGAffineTransformTranslate(uiCoords, cropSize.width / 2, cropSize.height / 2);
    uiCoords = CGAffineTransformScale(uiCoords, 1.0, -1.0);
    
    CGContextConcatCTM(context, uiCoords);
    CGContextConcatCTM(context, transform);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextDrawImage(context, CGRectMake(-imageViewSize.width/2.0,
                                           -imageViewSize.height/2.0,
                                           imageViewSize.width,
                                           imageViewSize.height), sourceImage.CGImage);
    
    CGImageRef resultRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    UIImage *newImage = [[UIImage alloc] initWithCGImage:resultRef];
    CGImageRelease(resultRef);
    return newImage;
}



@end
