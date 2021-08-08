//
//  PBHitService.h
//  PixabayTest
//
//  Created by Alexander Zaporozhchenko on 5/12/16.
//  Copyright © 2016 Alexander Zaporozhchenko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RACSignal.h"

@interface PBHitService : NSObject

@property (nonatomic, strong) NSString *searchKeyword;
@property (nonatomic) NSInteger page;
@property (nonatomic) NSInteger total;
@property (nonatomic) NSInteger totalHits;
@property (nonatomic) NSInteger currentCount;

@property (nonatomic, copy) NSString * _Nullable key;

+ (instancetype)sharedInstance;
- (RACSignal *)getPBHits;
- (RACSignal *)getPBHitsFromNextPage;
@end
