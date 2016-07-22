//
//  OSVSlider.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 14/07/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVSlider.h"

@implementation OSVSlider

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];

    if (_knowWidth) {
        
        float lineWidth = 2.0;

        CAShapeLayer *circleLayer = [CAShapeLayer layer];
        [circleLayer setBounds:CGRectMake(_knowWidth-lineWidth, (-rect.size.height+_knowWidth)/2.0, _knowWidth, _knowWidth)];
        [circleLayer setPosition:CGPointMake(_knowWidth/2.0, _knowWidth/2.0)];
        UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0.0f, 0.0f, _knowWidth, _knowWidth)];
        [circleLayer setPath:[path CGPath]];
        [circleLayer setStrokeColor:[UIColor whiteColor].CGColor];
        [circleLayer setLineWidth:lineWidth];
        [circleLayer setFillColor:[UIColor clearColor].CGColor];
        
        [self.layer addSublayer:circleLayer];
        
        circleLayer = [CAShapeLayer layer];
        [circleLayer setBounds:CGRectMake(-rect.size.width+lineWidth, (-rect.size.height+_knowWidth)/2.0, _knowWidth, _knowWidth)];
        [circleLayer setPosition:CGPointMake(_knowWidth/2.0, _knowWidth/2.0)];
        path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0.0f, 0.0f, _knowWidth, _knowWidth)];
        [circleLayer setPath:[path CGPath]];
        [circleLayer setStrokeColor:[UIColor whiteColor].CGColor];
        [circleLayer setLineWidth:lineWidth];
        [circleLayer setFillColor:[UIColor clearColor].CGColor];
        
        [self.layer addSublayer:circleLayer];
    }
}


@end
