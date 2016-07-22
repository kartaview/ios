//
//  CERangeSliderKnobLayer.m
//  CERangeSlider
//
//  Created by Colin Eberhardt on 24/03/2013.
//  Copyright (c) 2013 Colin Eberhardt. All rights reserved.
//

#import "CERangeSliderKnobLayer.h"
#import "CERangeSlider.h"

@implementation CERangeSliderKnobLayer


- (void)drawInContext:(CGContextRef)ctx {
    CGRect knobFrame = self.bounds;
    
    UIBezierPath *knobPath = [UIBezierPath bezierPathWithRoundedRect:knobFrame
                                                        cornerRadius:0];
    
    // 1) fill - with a subtle shadow
    CGContextSetFillColorWithColor(ctx, [UIColor redColor].CGColor);
    CGContextAddPath(ctx, knobPath.CGPath);
    CGContextFillPath(ctx);

    // 4) highlight
    if (self.highlighted)
    {
        // fill
        CGContextSetFillColorWithColor(ctx, [UIColor colorWithWhite:0.0 alpha:0.1].CGColor);
        CGContextAddPath(ctx, knobPath.CGPath);
        CGContextFillPath(ctx);
    }
}

@end
