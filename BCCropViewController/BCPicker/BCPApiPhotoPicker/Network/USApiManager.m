//
//  USApiManager.m
//  BCPicker
//
//  Created by Somoy Das Gupta on 1/2/21.
//

#import "USApiManager.h"
#import "AFHTTPSessionManager+RACExtensions.h"

@interface USApiManager ()

@property (strong, nonatomic) AFHTTPSessionManager *sessionManager;

@end

static NSString * const kDefaultSearchString = @"new";
static NSString * const kApiKey              = @"MDZDFht52MrOo_evEGFxl4MMiYLKiPhH868EZktPRvg";
static NSInteger const kImageLimit           = 100;

static NSString * const kBaseURL      = @"https://api.unsplash.com/search/photos";
static NSString * const kKey          = @"client_id";
static NSString * const kSearchString = @"query";
static NSString * const kLimitPerPage = @"per_page";
static NSString * const kPage   = @"page";

@implementation USApiManager

+ (instancetype)sharedManager
{
    static USApiManager *sharedManager;
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
    [_sessionManager.requestSerializer setValue:@"v1" forHTTPHeaderField:@"Accept-Version"];
    
    return self;
}

#pragma mark - Public

- (RACSignal *)loadImagesWithSearchString:(NSString  * _Nullable)keyword {
    
    NSDictionary *parameters = @{ kKey : _key ? _key : kApiKey,
                                  kSearchString : ((keyword != nil && keyword.length > 0) ? keyword : kDefaultSearchString),
                                  kLimitPerPage : [NSNumber numberWithInt:kImageLimit]
    };
    
    NSLog(@"USApiManager loadImagesWithDefaultSearchString : %@",parameters);
    
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
    
    NSLog(@"USApiManager loadImagesWithDefaultSearchString : %@",parameters);
    
    return [_sessionManager rac_requestWithMethod:GET
                                              URL:@""
                                       parameters:parameters];
}

@end
