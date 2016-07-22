//
//  OSVCloseButton.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 14/07/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVCloseButton.h"

@implementation OSVCloseButton


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    CAShapeLayer *circleLayer = [CAShapeLayer layer];
    // Give the layer the same bounds as your image view
    [circleLayer setBounds:CGRectMake(0.0f, 0.0f, self.bounds.size.width,
                                      self.bounds.size.width)];
    [circleLayer setPosition:CGPointMake(self.bounds.size.width/2.0, self.bounds.size.height/2.0)];
    // In the parent layer, which will be your image view's root layer
    // Create a circle path.
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:
                          CGRectMake(0.0f, 0.0f, self.bounds.size.width, self.bounds.size.width)];
    // Set the path on the layer
    [circleLayer setPath:[path CGPath]];
    // Set the stroke color
    [circleLayer setStrokeColor:[[UIColor whiteColor] colorWithAlphaComponent:0.7].CGColor];
    // Set the stroke line width
    [circleLayer setLineWidth:5.0f];
    [circleLayer setFillColor:[UIColor clearColor].CGColor];
    
    // Add the sublayer to the image view's layer tree
    [self.layer addSublayer:circleLayer];
}


@end
