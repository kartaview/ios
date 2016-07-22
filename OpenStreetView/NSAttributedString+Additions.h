//
//  NSAttributedString+Additions.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 12/07/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NSAttributedString (Additions)

+ (NSAttributedString *)attributedStringWithString:(NSString *)text withSize:(float)textSize color:(UIColor *)textColor fontName:(NSString *)textFont;
+ (NSAttributedString *)combineString:(NSString *)text withSize:(float)textSize color:(UIColor *)textColor fontName:(NSString *)textFont
                           withString:(NSString *)secondtext withSize:(float)secondSize color:(UIColor *)secondColor fontName:(NSString *)sencondFont;

- (NSMutableAttributedString *)appendString:(NSString *)aString withSize:(float)textSize color:(UIColor *)textColor fontName:(NSString *)textfont;

@end
