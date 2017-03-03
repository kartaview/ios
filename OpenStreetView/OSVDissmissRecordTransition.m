//
//  OSVDissmissRecordTransition.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 10/10/2016.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVDissmissRecordTransition.h"
#import "OSVCamViewController.h"

@implementation OSVDissmissRecordTransition

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.4;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    OSVCamViewController *source = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *destination = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    NSTimeInterval transitionDuration = [self transitionDuration:transitionContext];
    destination.view.alpha = 0.0;
    destination.view.frame = transitionContext.containerView.frame;

    [transitionContext.containerView addSubview:destination.view];
    
    source.view.alpha = 1.0;
    
    [UIView animateKeyframesWithDuration:transitionDuration
                                   delay:0.0
                                 options:UIViewKeyframeAnimationOptionCalculationModeCubic
                              animations:^{
                                  
        [UIView addKeyframeWithRelativeStartTime:0.0
                                relativeDuration:1.0
                                      animations:^{
                                        destination.view.alpha = 1.0;
                                        source.view.alpha = 0.2;
        }];
                                  
        [UIView addKeyframeWithRelativeStartTime:0.0
                              relativeDuration:0.7
                                    animations:^{
                                        source.sugestionLabel.frame = CGRectOffset(source.sugestionLabel.frame, 0, 40);
                                        source.arrowImage.frame = CGRectOffset(source.arrowImage.frame, 0, 40);
                                    }];
    } completion:^(BOOL finished) {
        [source removeFromParentViewController];
        [transitionContext completeTransition:YES];
    }];
}

@end
