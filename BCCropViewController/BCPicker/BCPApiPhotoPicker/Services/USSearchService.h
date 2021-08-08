//
//  USSearchService.h
//  BCPicker
//
//  Created by Somoy Das Gupta on 1/2/21.
//

#import <Foundation/Foundation.h>
#import "RACSignal.h"

NS_ASSUME_NONNULL_BEGIN

@interface USSearchService : NSObject

@property (nonatomic, strong) NSString *searchKeyword;
@property (nonatomic) NSInteger page;
@property (nonatomic) NSInteger total;
@property (nonatomic) NSInteger totalPages;

@property (nonatomic, copy) NSString * _Nullable key;

+ (instancetype)sharedInstance;
- (RACSignal *)getUSResults;
- (RACSignal *)getUSResultsFromNextPage;
@end

NS_ASSUME_NONNULL_END
