//
//  USResult.m
//  BCPicker
//
//  Created by Somoy Das Gupta on 1/2/21.
//

#import "USResult.h"

@implementation USUrls

+ (FEMMapping *)defaultMapping
{
    FEMMapping *mapping = [[FEMMapping alloc] initWithObjectClass:self];
    [mapping addAttributesFromArray:@[@"raw", @"full", @"regular", @"small", @"thumb"]];
    
    return mapping;
}

@end

@implementation USLinks

+ (FEMMapping *)defaultMapping
{
    FEMMapping *mapping = [[FEMMapping alloc] initWithObjectClass:self];
    [mapping addAttributesFromDictionary:@{@"link" : @"self", @"downloadLocation" : @"download_location"}];
    [mapping addAttributesFromArray:@[@"html", @"download"]];
    
    return mapping;
}

@end

@implementation USUser

+ (FEMMapping *)defaultMapping
{
    FEMMapping *mapping = [[FEMMapping alloc] initWithObjectClass:self];
    [mapping addAttributesFromArray:@[@"username", @"name"]];
    [mapping addAttributesFromDictionary:@{@"firstName" : @"first_name", @"lastName" : @"last_name"}];
    
    return  mapping;
}

@end

@implementation USResult

+ (FEMMapping *)defaultMapping
{
    FEMMapping *mapping = [[FEMMapping alloc] initWithObjectClass:self];
//    mapping.rootPath    = @"hits";
    [mapping addAttributesFromArray:@[@"id", @"width", @"height"]];
    [mapping addAttributesFromDictionary:@{@"desc" : @"description"}];
    [mapping addRelationshipMapping:[USUrls defaultMapping] forProperty:@"urls" keyPath:@"urls"];
    [mapping addRelationshipMapping:[USLinks defaultMapping] forProperty:@"links" keyPath:@"links"];
    [mapping addRelationshipMapping:[USUser defaultMapping] forProperty: @"user" keyPath: @"user"];
    
    
    return mapping;
}

@end
