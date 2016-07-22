//
//  NSAttributedString+Additions.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 12/07/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "NSAttributedString+Additions.h"

@implementation NSAttributedString (Additions)

+ (NSAttributedString *)attributedStringWithString:(NSString *)text withSize:(float)textSize color:(UIColor *)textColor fontName:(NSString *)textFont {
    if (!text) {
        text = @"";
    }

    NSRange range = NSMakeRange(0, [text length]);
    NSMutableAttributedString *attSpace = [[NSMutableAttributedString alloc] initWithString:text];
    [attSpace addAttribute:NSForegroundColorAttributeName value:textColor range:range];
    [attSpace addAttribute:NSFontAttributeName value:[UIFont fontWithName:textFont size:textSize] range:range];
    
    return attSpace;
}

+ (NSAttributedString *)combineString:(NSString *)text withSize:(float)textSize color:(UIColor *)textColor fontName:(NSString *)textFont
                           withString:(NSString *)stext withSize:(float)secSize color:(UIColor *)secoColor fontName:(NSString *)secoFont {
    if (!text) {
        text = @"";
    }
    
    if (!stext) {
        stext = @"";
    }
        
    NSRange range = NSMakeRange(0, [text length]);
    NSMutableAttributedString *attSpace = [[NSMutableAttributedString alloc] initWithString:text];
    [attSpace addAttribute:NSForegroundColorAttributeName value:textColor range:range];
    [attSpace addAttribute:NSFontAttributeName value:[UIFont fontWithName:textFont size:textSize] range:range];
    
    range = NSMakeRange(0, [stext length]);
    NSMutableAttributedString *att1 = [[NSMutableAttributedString alloc] initWithString:stext];
    [att1 addAttribute:NSForegroundColorAttributeName value:secoColor range:range];
    [att1 addAttribute:NSFontAttributeName value:[UIFont fontWithName:secoFont size:secSize] range:range];
    [attSpace appendAttributedString:att1];
    
    return attSpace;
}

- (NSMutableAttributedString *)appendString:(NSString *)aString withSize:(float)textSize color:(UIColor *)textColor fontName:(NSString *)textfont {
    if (!aString) {
        aString = @"";
    }
    
    NSRange range = NSMakeRange(0, [aString length]);
    NSMutableAttributedString *attSpace = [[NSMutableAttributedString alloc] initWithString:aString];
    [attSpace addAttribute:NSForegroundColorAttributeName value:textColor range:range];
    [attSpace addAttribute:NSFontAttributeName value:[UIFont fontWithName:textfont size:textSize] range:range];
    
    return attSpace;
}

@end
