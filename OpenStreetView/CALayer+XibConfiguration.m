//
//  CALayer+XibConfiguration.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 12/07/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "CALayer+XibConfiguration.h"

@implementation CALayer (XibConfiguration)

- (void)setBorderUIColor:(UIColor *)color {
    self.borderColor = color.CGColor;
}

- (UIColor *)borderUIColor {
    return [UIColor colorWithCGColor:self.borderColor];
}

@end
