//
//  PBResponse.m
//  BCPicker
//
//  Created by Somoy Das Gupta on 1/2/21.
//

#import "PBResponse.h"

@implementation PBResponse

+ (FEMMapping *)defaultMapping {
    FEMMapping *mapping = [[FEMMapping alloc] initWithObjectClass:self];
    [mapping addAttributesFromArray:@[@"total", @"totalHits"]];
    
    [mapping addToManyRelationshipMapping:[PBHit defaultMapping] forProperty:@"hits" keyPath:@"hits"];
    
    return mapping;
}

@end
