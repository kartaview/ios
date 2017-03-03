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

+ (NSAttributedString *)combineString:(NSString *)text1 withSize:(float)textSize color:(UIColor *)textColor fontName:(NSString *)textFont
                           withString:(NSString *)text2 withSize:(float)secSize color:(UIColor *)secoColor fontName:(NSString *)secoFont
                       adjustBaseline:(BOOL)adjust {
    if (!text1) {
        text1 = @"";
    }
    
    if (!text2) {
        text2 = @"";
    }
    
    NSRange range1 = NSMakeRange(0, [text1 length]);
    NSMutableAttributedString *att1 = [[NSMutableAttributedString alloc] initWithString:text1];
    [att1 addAttribute:NSForegroundColorAttributeName value:textColor range:range1];
    UIFont *font1 = [UIFont fontWithName:textFont size:textSize];
    [att1 addAttribute:NSFontAttributeName value:font1 range:range1];
    
    NSRange range2 = NSMakeRange(0, [text2 length]);
    NSMutableAttributedString *att2 = [[NSMutableAttributedString alloc] initWithString:text2];
    [att2 addAttribute:NSForegroundColorAttributeName value:secoColor range:range2];
    UIFont *font2 = [UIFont fontWithName:secoFont size:secSize];
    [att2 addAttribute:NSFontAttributeName value:font2 range:range2];
    
    if (adjust) {
        if (font1.capHeight < font2.capHeight) {
            float value = font2.capHeight - font1.capHeight;
            [att1 addAttribute:NSBaselineOffsetAttributeName value:@(value/2.0) range:range1];
        } else {
            float value = font1.capHeight - font2.capHeight;
            [att2 addAttribute:NSBaselineOffsetAttributeName value:@(value/2.0) range:range2];
        }
    }
    
    [att1 appendAttributedString:att2];

    return att1;
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
