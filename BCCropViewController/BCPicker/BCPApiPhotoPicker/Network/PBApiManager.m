//
//  PBApiManager.m
//  PixabayTest
//
//  Created by Alexander Zaporozhchenko on 5/12/16.
//  Copyright © 2016 Alexander Zaporozhchenko. All rights reserved.
//

#import "PBApiManager.h"
#import "AFHTTPSessionManager+RACExtensions.h"

@interface PBApiManager ()
@property (strong, nonatomic) AFHTTPSessionManager *sessionManager;

@end

static NSString * const kDefaultSearchString = @"";
static NSString * const kApiKey              = @"20094913-f6e150763af3f3ad3a2feace3";
static NSInteger  const kImageLimit          = 100;

static NSString * const kBaseURL      = @"https://pixabay.com/api/";
static NSString * const kKey          = @"key";
static NSString * const kSearchString = @"q";
static NSString * const kLimitPerPage = @"per_page";
static NSString * const kPage         = @"page";



@implementation PBApiManager

#pragma mark - Initialization

+ (instancetype)sharedManager
{
    static PBApiManager *sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [self new];
    });
    
    return sharedManager;
}

- (instancetype) init
{
    self                              = [super init];
    NSURL *baseURL                    = [NSURL URLWithString:kBaseURL];
    _sessionManager                   = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
    _sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    return self;
}

#pragma mark - Public

- (RACSignal *)loadImagesWithSearchString:(NSString  * _Nullable)keyword {
    
    NSDictionary *parameters = @{ kKey : _key ? _key : kApiKey,
                                  kSearchString : ((keyword != nil && keyword.length > 0) ? keyword : kDefaultSearchString),
                                  kLimitPerPage : [NSNumber numberWithInt:kImageLimit]
    };
    
    NSLog(@"PBApiManager loadImagesWithDefaultSearchString : %@",parameters);
    
    return [_sessionManager rac_requestWithMethod:GET
                                              URL:@""
                                       parameters:parameters];
}

- (RACSignal *)loadImagesWithSearchString:(NSString  * _Nullable)keyword page:(NSInteger)pageNumber {
    
    NSDictionary *parameters = @{ kKey : _key ? _key : kApiKey,
                                  kSearchString : ((keyword != nil && keyword.length > 0) ? keyword : kDefaultSearchString),
                                  kLimitPerPage : [NSNumber numberWithInt:kImageLimit],
                                  kPage : [NSNumber numberWithInteger:pageNumber]
    };
    
    NSLog(@"PBApiManager loadImagesWithDefaultSearchString : %@",parameters);
    
    return [_sessionManager rac_requestWithMethod:GET
                                              URL:@""
                                       parameters:parameters];
}

@end
