//
//  USResult.h
//  BCPicker
//
//  Created by Somoy Das Gupta on 1/2/21.
//

#import <Foundation/Foundation.h>
#import "FEMMapping.h"

NS_ASSUME_NONNULL_BEGIN

@interface USUrls : NSObject

@property (nonatomic, copy) NSString *raw;
@property (nonatomic, copy) NSString *full;
@property (nonatomic, copy) NSString *regular;
@property (nonatomic, copy) NSString *small;
@property (nonatomic, copy) NSString *thumb;

+ (FEMMapping *)defaultMapping;

@end

@interface USLinks : NSObject

@property (nonatomic, copy) NSString *downloadLocation;
@property (nonatomic, copy) NSString *link;
@property (nonatomic, copy) NSString *html;
@property (nonatomic, copy) NSString *download;

+ (FEMMapping *)defaultMapping;

@end

@interface USUser : NSObject

@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;

+ (FEMMapping *)defaultMapping;

@end

@interface USResult : NSObject

@property (nonatomic, strong) NSString *id;
@property (nonatomic, strong) NSNumber *width;
@property (nonatomic, strong) NSNumber *height;
@property (nonatomic, strong) NSString *desc;
@property (nonatomic, strong) USUrls *urls;
@property (nonatomic, strong) USLinks *links;
@property (nonatomic, strong) USUser *user;

+ (FEMMapping *)defaultMapping;

@end

NS_ASSUME_NONNULL_END
