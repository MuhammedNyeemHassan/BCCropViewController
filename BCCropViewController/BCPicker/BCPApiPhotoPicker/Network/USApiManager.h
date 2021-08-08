//
//  USApiManager.h
//  BCPicker
//
//  Created by Somoy Das Gupta on 1/2/21.
//

#import <Foundation/Foundation.h>
#import "ReactiveCocoa.h"

NS_ASSUME_NONNULL_BEGIN

@interface USApiManager : NSObject

+ (instancetype)sharedManager;
- (RACSignal *)loadImagesWithSearchString:(NSString  * _Nullable)keyword;
- (RACSignal *)loadImagesWithSearchString:(NSString  * _Nullable)keyword page:(NSInteger)pageNumber;
@property (nonatomic, copy) NSString * _Nullable key;

@end

NS_ASSUME_NONNULL_END
