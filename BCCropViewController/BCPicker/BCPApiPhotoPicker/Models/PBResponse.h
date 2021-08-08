//
//  PBResponse.h
//  BCPicker
//
//  Created by Somoy Das Gupta on 1/2/21.
//

#import <Foundation/Foundation.h>
#import "FEMMapping.h"
#import "PBHit.h"

NS_ASSUME_NONNULL_BEGIN

@interface PBResponse : NSObject

@property (nonatomic, strong) NSNumber *total;
@property (nonatomic, strong) NSNumber *totalHits;
@property (nonatomic, strong) NSMutableArray<PBHit*> *hits;

+ (FEMMapping *)defaultMapping;

@end

NS_ASSUME_NONNULL_END
