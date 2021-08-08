//
//  USResponse.m
//  BCPicker
//
//  Created by Somoy Das Gupta on 1/2/21.
//

#import "USResponse.h"

@implementation USResponse

+ (FEMMapping *)defaultMapping {
    FEMMapping *mapping = [[FEMMapping alloc] initWithObjectClass:self];
    [mapping addAttributesFromArray:@[@"total"]];
    [mapping addAttributesFromDictionary:@{@"totalPages" : @"total_pages"}];
    
    [mapping addToManyRelationshipMapping:[USResult defaultMapping] forProperty:@"results" keyPath:@"results"];
    
    return mapping;
}

@end
