//
//  UIView+Additions.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 14/07/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "UIView+Additions.h"

@implementation UIView (Additions)

- (void)setColorPatternWithImageName:(NSString *)imageName {
    [self setBackgroundColor:[[UIColor colorWithPatternImage:[UIImage imageNamed:imageName]] colorWithAlphaComponent:0.3]];
}

@end
