//
//  OSVCropedLabel.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 03/12/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import "OSVCropedLabel.h"

@implementation OSVCropedLabel

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    [[UIColor whiteColor] setFill];
    UIRectFill(rect);
    
    [super drawRect:rect];

    CGRect holeRectIntersection = CGRectMake(CGRectGetMidX(rect) - 37.5, CGRectGetMinY(rect) - 70, 75, 75);
    
    if (CGRectIntersectsRect( holeRectIntersection, rect )) {
        CGContextAddEllipseInRect(context, holeRectIntersection);
        CGContextClip(context);
        CGContextClearRect(context, holeRectIntersection);
        CGContextSetFillColorWithColor( context, [UIColor clearColor].CGColor );
        CGContextFillRect( context, holeRectIntersection);
    }
}

@end
