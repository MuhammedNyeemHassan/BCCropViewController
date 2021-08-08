//
//  PBHit.h
//  PixabayTest
//
//  Created by Alexander Zaporozhchenko on 5/12/16.
//  Copyright © 2016 Alexander Zaporozhchenko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FEMMapping.h"

@interface PBHit : NSObject

@property (nonatomic, copy) NSString *id;
@property (nonatomic, copy) NSString *pageURL;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSString    *previewURL;
@property (nonatomic, copy) NSString *tags;
@property (nonatomic, copy) NSNumber *previewWidth;
@property (nonatomic, copy) NSNumber *previewHeight;
@property (nonatomic, copy) NSString *user;
@property (nonatomic, copy) NSString    *webformatURL;
@property (nonatomic, copy) NSNumber *webformatWidth;
@property (nonatomic, copy) NSNumber *webformatHeight;
@property (nonatomic, copy) NSString    *largeImageURL;
@property (nonatomic, copy) NSString    *fullHDURL;
@property (nonatomic, copy) NSString    *imageURL;
@property (nonatomic, copy) NSNumber *imageWidth;
@property (nonatomic, copy) NSNumber *imageHeight;
@property (nonatomic, copy) NSNumber *imageSize;

+ (FEMMapping *)defaultMapping;

@end
