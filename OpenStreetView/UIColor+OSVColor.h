//
//  UIColor+OSVColor.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 21/11/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (OSVColor)

// Blue highlighted
+ (UIColor *)hex03A9F4;
//Gray
+ (UIColor *)hex3A3A3A;

// Blue
+ (UIColor *)hex0F73C6;
// Gray
+ (UIColor *)hexB6B6B6;
+ (UIColor *)hex727272;
// Red
+ (UIColor *)hexF44336;

+ (UIColor *)hex30E162;

+ (UIColor *)hexFFCC48;
//dark blue
+ (UIColor *)hex0080FF;
//gray light
+ (UIColor *)hex878787;

//bar tint blue 
+ (UIColor *)hex05ABF2;
//fill colors for polylines
+ (UIColor *)hex258DBA;
+ (UIColor *)hex68BDE3;
//Green 
+ (UIColor *)hex63AB4F;
//blue camera
+ (UIColor *)hex007AFF;
//blue myProfile
+ (UIColor *)hex019ED3;
//dark color myProfile
+ (UIColor *)hex1B1C1F;
//gray text color
+ (UIColor *)hexB7BAC5;
+ (UIColor *)hex6E707B;
+ (UIColor *)hexBD10E0;
+ (UIColor *)hex31333B;
+ (UIColor *)hex1DAA63;


+ (UIColor *)colorWithHex:(NSInteger)hex;

@end
