//
//  PBHitService.m
//  PixabayTest
//
//  Created by Alexander Zaporozhchenko on 5/12/16.
//  Copyright © 2016 Alexander Zaporozhchenko. All rights reserved.
//

#import "PBHitService.h"
#import "PBApiManager.h"
#import "FEMMapping.h"
#import "PBResponse.h"
#import "FEMDeserializer.h"

@implementation PBHitService

+ (instancetype)sharedInstance
{
    static PBHitService *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    
    return sharedInstance;
}

- (void)setKey:(NSString * _Nullable)key {
    _key = key;
    PBApiManager.sharedManager.key = _key;
}

- (RACSignal *)getPBHits
{
    self.page = 1;
    self.total = 0;
    self.totalHits = 0;
    self.currentCount = 0;
    
    return  [[[PBApiManager sharedManager] loadImagesWithSearchString:self.searchKeyword] map:^id(id response) {
        FEMMapping *mapping      = [PBResponse defaultMapping];
        PBResponse *pbResponse   = [FEMDeserializer objectFromRepresentation:response mapping:mapping];
        self.page = 1;
        self.total = pbResponse.total.integerValue;
        self.totalHits = pbResponse.totalHits.integerValue;
        self.currentCount += pbResponse.hits.count;
        return pbResponse;
    }];
}

- (RACSignal *)getPBHitsFromNextPage {
    
    if (![self hasNextPage])
        return RACSignal.empty;
    
    return [[[PBApiManager sharedManager] loadImagesWithSearchString:self.searchKeyword page:(self.page + 1)] map:^id(id response) {
        FEMMapping *mapping      = [PBResponse defaultMapping];
        PBResponse *pbResponse   = [FEMDeserializer objectFromRepresentation:response mapping:mapping];
        self.page += 1;
        self.total = pbResponse.total.integerValue;
        self.totalHits = pbResponse.totalHits.integerValue;
        return pbResponse.hits;
    }];
}

- (BOOL)hasNextPage {
    return self.total > self.currentCount;
}

@end
