//
//  UIColor+Hexadecimal.m
//  Applications
//
//  Created by Ignacio on 6/7/14.
//  Copyright (c) 2014 DZN Labs. All rights reserved.
//

#import "UIColor+Hexadecimal.h"

@implementation UIColor (Hexadecimal)

+ (UIColor *)colorWithHex:(NSString *)string
{
    NSString *cleanString = [string stringByReplacingOccurrencesOfString:@"#" withString:@""];
    if([cleanString length] == 3) {
        cleanString = [NSString stringWithFormat:@"%@%@%@%@%@%@",
                       [cleanString substringWithRange:NSMakeRange(0, 1)],[cleanString substringWithRange:NSMakeRange(0, 1)],
                       [cleanString substringWithRange:NSMakeRange(1, 1)],[cleanString substringWithRange:NSMakeRange(1, 1)],
                       [cleanString substringWithRange:NSMakeRange(2, 1)],[cleanString substringWithRange:NSMakeRange(2, 1)]];
    }
    if([cleanString length] == 6) {
        cleanString = [cleanString stringByAppendingString:@"ff"];
    }
    
    unsigned int baseValue;
    [[NSScanner scannerWithString:cleanString] scanHexInt:&baseValue];
    
    float red = ((baseValue >> 24) & 0xFF)/255.0f;
    float green = ((baseValue >> 16) & 0xFF)/255.0f;
    float blue = ((baseValue >> 8) & 0xFF)/255.0f;
    float alpha = (baseValue & 0xFF)/255.0f;;
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

- (NSString *)hexString {
    
    const CGFloat *components = CGColorGetComponents(self.CGColor);
    CGFloat r = components[0];
    CGFloat g = components[1];
    CGFloat b = components[2];
    CGFloat a = components[3];
    
    NSString *hexString=[NSString stringWithFormat:@"%02X%02X%02X%02X", (int)(r * 255), (int)(g * 255), (int)(b * 255), (int)(a * 255)];
    return hexString;
}

@end
