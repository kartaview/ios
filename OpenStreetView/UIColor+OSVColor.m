//
//  UIColor+OSVColor.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 21/11/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import "UIColor+OSVColor.h"

@implementation UIColor (OSVColor)

+ (UIColor *)hex03A9F4 {
    return [self colorFromSelector:_cmd];
}

+ (UIColor *)hex3A3A3A {
    return [self colorFromSelector:_cmd];
}

+ (UIColor *)hex0F73C6 {
    return [self colorFromSelector:_cmd];
}

+ (UIColor *)hexB6B6B6 {
    return [self colorFromSelector:_cmd];
}

+ (UIColor *)hex727272 {
    return [self colorFromSelector:_cmd];
}

+ (UIColor *)hexF44336 {
    return [self colorFromSelector:_cmd];
}

+ (UIColor *)hex30E162 {
    return [self colorFromSelector:_cmd];
}

+ (UIColor *)hexFFCC48 {
    return [self colorFromSelector:_cmd];
}

+ (UIColor *)hex0080FF {
    return [self colorFromSelector:_cmd];
}

+ (UIColor *)hex878787 {
    return [self colorFromSelector:_cmd];
}

+ (UIColor *)hex05ABF2 {
    return [self colorFromSelector:_cmd];
}

+ (UIColor *)hex258DBA {
    return [self colorFromSelector:_cmd];
}

+ (UIColor *)hex68BDE3 {
    return [self colorFromSelector:_cmd];
}

+ (UIColor *)hex63AB4F {
    return [self colorFromSelector:_cmd];
}

+ (UIColor *)hex007AFF {
    return [self colorFromSelector:_cmd];
}

+ (UIColor *)hex019ED3 {
    return [self colorFromSelector:_cmd];
}

+ (UIColor *)hex1B1C1F {
    return [self colorFromSelector:_cmd];
}

+ (UIColor *)hexB7BAC5 {
    return [self colorFromSelector:_cmd];
}

+ (UIColor *)hex6E707B {
    return [self colorFromSelector:_cmd];
}

+ (UIColor *)hexBD10E0 {
    return [self colorFromSelector:_cmd];
}

+ (UIColor *)hex31333B {
    return [self colorFromSelector:_cmd];
}

+ (UIColor *)hex1DAA63 {
    return [self colorFromSelector:_cmd];
}

+ (UIColor *)colorFromSelector:(SEL)selector {
    NSString *name = NSStringFromSelector(selector);
    unsigned result = 0;
    NSScanner *scanner = [NSScanner scannerWithString:name];
    [scanner setScanLocation:3]; // bypass 'hex' character
    [scanner scanHexInt:&result];
    
    return [self colorWithHex:result];
}

+ (UIColor *)colorWithHex:(NSInteger)hex {
    if (hex <= 0xFFFFFF) {
        return [UIColor colorWithRed:((float)((hex & 0xFF0000) >> 16)) / 255.0
                               green:((float)((hex & 0xFF00) >> 8)) / 255.0
                                blue:((float)(hex & 0xFF)) / 255.0
                               alpha:1.0];
    } else {
        return [UIColor colorWithRed:((float)((hex & 0xFF0000) >> 16)) / 255.0
                               green:((float)((hex & 0xFF00) >> 8)) / 255.0
                                blue:((float)(hex & 0xFF)) / 255.0
                               alpha:((float)((hex & 0xFF000000) >> 24)) / 255.0];
    }
}

@end
