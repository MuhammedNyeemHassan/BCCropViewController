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
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    UIImage *croppedImage = [self cropResultWithImage:image];
    return croppedImage;
}

-(UIImage *)cropResultWithImage:(UIImage*)sourceMainImg
{
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    // translate
    CGPoint translation  = self.imageTranslationPoint;
    transform = CGAffineTransformTranslate(transform, translation.x, translation.y);
    
    // rotate
    transform = CGAffineTransformRotate(transform, self.rotationAngle);
        
    CGImageRef newCgIm = CGImageCreateCopy(sourceMainImg.CGImage);
    UIImage *img = [UIImage imageWithCGImage:newCgIm scale:sourceMainImg.scale orientation:sourceMainImg.imageOrientation];
    CGImageRelease(newCgIm);
    CGImageRef fixedImage = [self cgImageWithFixedOrientation: img];
    CGImageRef imageRef = [self transformedImage:transform :fixedImage :self.zoomScale :sourceMainImg.size :self.cropSize :self.imageLayerSize];
    CGImageRelease(fixedImage);
    UIImage *image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return image;
}


-(CGImageRef)cgImageWithFixedOrientation:(UIImage *)img {
    
    CGImageRef cgImage = [img CGImage];
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(cgImage);
    
    if (cgImage == nil || colorSpace == nil) {
        return nil;
    }
    
    if (img.imageOrientation == UIImageOrientationUp) {
        return img.CGImage;
    }
    
    CGFloat width  = img.size.width;
    CGFloat height = img.size.height;
    
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
    
    CGImageRelease(cgImage);
    // And now we just create a new UIImage from the drawing context
    CGImageRef newCGImg = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    return newCGImg;
}

-(CGImageRef)transformedImage:(CGAffineTransform)transform
                             :(CGImageRef)sourceImage
                             :(CGFloat) zoomScale
                             :(CGSize) sourceSize
                             :(CGSize) cropSize
                             :(CGSize) imageViewSize {
    CGFloat expectedWidth = floor((sourceSize.width / imageViewSize.width) * cropSize.width) / zoomScale;
    CGFloat expectedHeight = floor((sourceSize.height / imageViewSize.height) * cropSize.height) / zoomScale;
    CGSize outputSize = CGSizeMake(expectedWidth, expectedHeight);
    int bitmapBytesPerRow = 0;
    
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 (int)outputSize.width,
                                                 (int)outputSize.height,
                                                 CGImageGetBitsPerComponent(sourceImage),
                                                 bitmapBytesPerRow,
                                                 CGImageGetColorSpace(sourceImage),
                                                 CGImageGetBitmapInfo(sourceImage)
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
                                           imageViewSize.height), sourceImage);
    
    CGImageRef resultRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    return resultRef;
}




@end
