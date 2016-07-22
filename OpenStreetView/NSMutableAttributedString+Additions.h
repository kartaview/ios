//
//  NSMutableAttributedString+Additions.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 13/07/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NSMutableAttributedString (Additions)
+ (instancetype)mutableAttributedStringWithString:(NSString *)text withSize:(float)textSize color:(UIColor *)textColor fontName:(NSString *)textFont;

@end
