//
//  OSVRecordTransition.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 10/10/2016.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVRecordTransition.h"
#import "OSVCamViewController.h"

@implementation OSVRecordTransition

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.5;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    OSVCamViewController    *destination = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];

    UIView *container = transitionContext.containerView;
    
    [destination beginAppearanceTransition:YES animated:YES];
    
    destination.view.alpha = 0.0;
    destination.view.frame = container.frame;
    [container addSubview:destination.view];
    NSTimeInterval transitionDuration = [self transitionDuration:transitionContext];
    [destination.view setNeedsLayout];
    [destination.view layoutIfNeeded];
    
    destination.sugestionLabel.frame = CGRectOffset(destination.sugestionLabel.frame, 0, 40);
    destination.arrowImage.frame = CGRectOffset(destination.arrowImage.frame, 0, 40);
    
    [UIView animateKeyframesWithDuration:transitionDuration
                                   delay:0.0
                                 options:UIViewKeyframeAnimationOptionCalculationModeCubic
                              animations:^{
                                  
        [UIView addKeyframeWithRelativeStartTime:0.0
                                relativeDuration:0.7
                                      animations:^{
            destination.view.alpha = 1;
        }];
                                  
        [UIView addKeyframeWithRelativeStartTime:0.0
                                relativeDuration:0.5
                                      animations:^{
            destination.sugestionLabel.frame = CGRectOffset(destination.sugestionLabel.frame, 0, -48);
            destination.arrowImage.frame = CGRectOffset(destination.arrowImage.frame, 0, -48);
        }];
                                  
        [UIView addKeyframeWithRelativeStartTime:0.5
                                relativeDuration:1.0
                                      animations:^{
            destination.sugestionLabel.frame = CGRectOffset(destination.sugestionLabel.frame, 0, 8);
            destination.arrowImage.frame = CGRectOffset(destination.arrowImage.frame, 0, 8);
        }];
    } completion:^(BOOL finished) {
        [destination endAppearanceTransition];
        [transitionContext completeTransition:finished];
    }];
}

@end
