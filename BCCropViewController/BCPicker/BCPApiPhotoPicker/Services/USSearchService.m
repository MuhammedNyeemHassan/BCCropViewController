//
//  USSearchService.m
//  BCPicker
//
//  Created by Somoy Das Gupta on 1/2/21.
//

#import "USSearchService.h"
#import "USApiManager.h"
#import "FEMMapping.h"
#import "USResponse.h"
#import "FEMDeserializer.h"

@implementation USSearchService

+ (instancetype)sharedInstance
{
    static USSearchService *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    
    return sharedInstance;
}

- (void)setKey:(NSString * _Nullable)key {
    _key = key;
    USApiManager.sharedManager.key = _key;
}

- (RACSignal *)getUSResults
{
    self.page = 1;
    self.total = 0;
    self.totalPages = 0;
    
    return  [[[USApiManager sharedManager] loadImagesWithSearchString:self.searchKeyword] map:^id(id response) {
        FEMMapping *mapping      = [USResponse defaultMapping];
        USResponse *usResponse   = [FEMDeserializer objectFromRepresentation:response mapping:mapping];
        self.page = 1;
        self.total = usResponse.total.integerValue;
        self.totalPages = usResponse.totalPages.integerValue;
        return usResponse;
    }];
}

- (RACSignal *)getUSResultsFromNextPage {
    
    if (![self hasNextPage])
        return RACSignal.empty;
    
    return [[[USApiManager sharedManager] loadImagesWithSearchString:self.searchKeyword page:(self.page + 1)] map:^id(id response) {
        FEMMapping *mapping      = [USResponse defaultMapping];
        USResponse *usResponse   = [FEMDeserializer objectFromRepresentation:response mapping:mapping];
        self.page += 1;
        self.total = usResponse.total.integerValue;
        self.totalPages = usResponse.totalPages.integerValue;
        return usResponse.results;
    }];
}

- (BOOL)hasNextPage {
    return self.page < self.totalPages;
}

@end
