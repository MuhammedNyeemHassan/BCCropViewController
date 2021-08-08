//
//  USResponse.h
//  BCPicker
//
//  Created by Somoy Das Gupta on 1/2/21.
//

#import <Foundation/Foundation.h>
#import "USResult.h"
#import "FEMMapping.h"

NS_ASSUME_NONNULL_BEGIN

@interface USResponse : NSObject

@property (nonatomic, strong) NSNumber *total;
@property (nonatomic, strong) NSNumber *totalPages;
@property (nonatomic, strong) NSMutableArray<USResult*> *results;

+ (FEMMapping *)defaultMapping;

@end

NS_ASSUME_NONNULL_END
