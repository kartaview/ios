//
//  UIViewController+Additions.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 01/02/2017.
//  Copyright © 2017 Bogdan Sala. All rights reserved.
//

#import "UIViewController+Additions.h"
#import "OSVUserDefaults.h"

@implementation UIViewController (Additions)

+ (void)addMapView:(UIView *)firstView toView:(UIView *)secView {
    if ([OSVUserDefaults sharedInstance].enableMap) {
        firstView.translatesAutoresizingMaskIntoConstraints = NO;
        NSLayoutConstraint *trailing = [NSLayoutConstraint
                                        constraintWithItem:firstView
                                        attribute:NSLayoutAttributeTrailing
                                        relatedBy:NSLayoutRelationEqual
                                        toItem:secView
                                        attribute:NSLayoutAttributeTrailing
                                        multiplier:1.0f
                                        constant:0.f];
        NSLayoutConstraint *leading = [NSLayoutConstraint
                                       constraintWithItem:firstView
                                       attribute:NSLayoutAttributeLeading
                                       relatedBy:NSLayoutRelationEqual
                                       toItem:secView
                                       attribute:NSLayoutAttributeLeading
                                       multiplier:1.0f
                                       constant:0.f];
        NSLayoutConstraint *bottom = [NSLayoutConstraint
                                      constraintWithItem:firstView
                                      attribute:NSLayoutAttributeBottom
                                      relatedBy:NSLayoutRelationEqual
                                      toItem:secView
                                      attribute:NSLayoutAttributeBottom
                                      multiplier:1.0f
                                      constant:0.f];
        NSLayoutConstraint *top = [NSLayoutConstraint
                                   constraintWithItem:firstView
                                   attribute:NSLayoutAttributeTop
                                   relatedBy:NSLayoutRelationEqual
                                   toItem:secView
                                   attribute:NSLayoutAttributeTop
                                   multiplier:1.0f
                                   constant:0.f];
        [secView addSubview:firstView];
        
        [secView addConstraints:@[trailing, leading, bottom, top]];
    } else {
        UIImageView *imageView = [UIImageView new];
        imageView.image = [UIImage imageNamed:@"splashscreen_background"];
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"oSVLogoV1"]];
        logo.translatesAutoresizingMaskIntoConstraints = NO;
        
        [secView addSubview:imageView];
        [secView addSubview:logo];
        
        NSLayoutConstraint *trailing = [NSLayoutConstraint
                                        constraintWithItem:imageView
                                        attribute:NSLayoutAttributeTrailing
                                        relatedBy:NSLayoutRelationEqual
                                        toItem:secView
                                        attribute:NSLayoutAttributeTrailing
                                        multiplier:1.0f
                                        constant:0.f];
        NSLayoutConstraint *leading = [NSLayoutConstraint
                                       constraintWithItem:imageView
                                       attribute:NSLayoutAttributeLeading
                                       relatedBy:NSLayoutRelationEqual
                                       toItem:secView
                                       attribute:NSLayoutAttributeLeading
                                       multiplier:1.0f
                                       constant:0.f];
        NSLayoutConstraint *bottom = [NSLayoutConstraint
                                      constraintWithItem:imageView
                                      attribute:NSLayoutAttributeBottom
                                      relatedBy:NSLayoutRelationEqual
                                      toItem:secView
                                      attribute:NSLayoutAttributeBottom
                                      multiplier:1.0f
                                      constant:0.f];
        NSLayoutConstraint *top = [NSLayoutConstraint
                                   constraintWithItem:imageView
                                   attribute:NSLayoutAttributeTop
                                   relatedBy:NSLayoutRelationEqual
                                   toItem:secView
                                   attribute:NSLayoutAttributeTop
                                   multiplier:1.0f
                                   constant:0.f];
        
        NSLayoutConstraint *centerX = [NSLayoutConstraint
                                       constraintWithItem:logo
                                       attribute:NSLayoutAttributeCenterX
                                       relatedBy:NSLayoutRelationEqual
                                       toItem:secView
                                       attribute:NSLayoutAttributeCenterX
                                       multiplier:1.0f
                                       constant:0.f];
        NSLayoutConstraint *centerY = [NSLayoutConstraint
                                       constraintWithItem:logo
                                       attribute:NSLayoutAttributeCenterY
                                       relatedBy:NSLayoutRelationEqual
                                       toItem:secView
                                       attribute:NSLayoutAttributeCenterY
                                       multiplier:1.0f
                                       constant:0.f];
        [secView addConstraints:@[trailing,leading,bottom,top,centerX,centerY]];
    }
}

@end
