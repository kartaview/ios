//
//  NSMutableAttributedString+Additions.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 13/07/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "NSMutableAttributedString+Additions.h"

@implementation NSMutableAttributedString (Additions)

+ (instancetype)mutableAttributedStringWithString:(NSString *)text withSize:(float)textSize color:(UIColor *)textColor fontName:(NSString *)textFont {
    
    NSRange range = NSMakeRange(0, [text length]);
    NSMutableAttributedString *attSpace = [[NSMutableAttributedString alloc] initWithString:text];
    [attSpace addAttribute:NSForegroundColorAttributeName value:textColor range:range];
    [attSpace addAttribute:NSFontAttributeName value:[UIFont fontWithName:textFont size:textSize] range:range];
    
    return attSpace;
}

@end
