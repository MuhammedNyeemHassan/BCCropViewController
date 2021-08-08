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
        self.cropRatio = [cropInfoDict objectForKey:@"cropRatio"];
        self.flipH = [[cropInfoDict objectForKey:@"flipH"] boolValue];
        self.flipV = [[cropInfoDict objectForKey:@"flipV"] boolValue];
        self.rotationValue = [[cropInfoDict objectForKey:@"rotationValue"] floatValue];
        self.skewHValue = [[cropInfoDict objectForKey:@"skewHValue"] floatValue];
        self.skewVValue = [[cropInfoDict objectForKey:@"skewVValue"] floatValue];
        self.zoomScale = [[cropInfoDict objectForKey:@"zoomScale"] floatValue];
        self.cropContentOffset = [cropInfoDict objectForKey:@"cropContentOffset"];
        self.cropScrollZoomRect = [cropInfoDict objectForKey:@"cropScrollZoomRect"];
        self.lastCropViewSize = [cropInfoDict objectForKey:@"lastCropViewSize"];
        

    }
    return self;
}
@end
