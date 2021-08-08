//
//  UIImage+Utility.m
//  BCCropViewController
//
//  Created by Somoy Das Gupta on 4/8/21.
//

#import "UIImage+Utility.h"

@implementation UIImage (Utility)

//MARK:- Convert to CGImageRef
- (CGImageRef)createCGImageRef {
    
    CIImage *ciImage = [[CIImage alloc] initWithImage:self];
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef ref = [context createCGImage:ciImage fromRect:ciImage.extent];
    
    return ref;
}

@end
