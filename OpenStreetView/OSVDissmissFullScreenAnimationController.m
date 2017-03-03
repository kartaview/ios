//
//  OSVDissmissFullScreenAnimationController.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 16/06/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVDissmissFullScreenAnimationController.h"
#import "OSVVideoPlayerViewController.h"
#import "OSVFullScreenImageViewController.h"
#import "OSVPlayer.h"

@implementation OSVDissmissFullScreenAnimationController

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.2;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {

    OSVFullScreenImageViewController *source = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    
    NSTimeInterval transitionDuration = [self transitionDuration:transitionContext];

    [UIView animateKeyframesWithDuration:transitionDuration
                                   delay:0.0
                                 options:UIViewKeyframeAnimationOptionCalculationModeCubic
                              animations:^{
                                
                                    [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:1.0 animations:^{
                                      source.imageView.frame = self.destinationFrame;
                                    }];
                              } completion:^(BOOL finished) {
                                     [transitionContext completeTransition:YES];
                              }];
    
}

@end
