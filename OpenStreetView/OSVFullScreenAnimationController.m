//
//  OSVFullScreenAnimationController.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 16/06/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVFullScreenAnimationController.h"
#import "OSVPlayer.h"
#import "OSVVideoPlayerViewController.h"
#import "OSVFullScreenImageViewController.h"

@implementation OSVFullScreenAnimationController

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.2;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    OSVFullScreenImageViewController    *destination = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *container = transitionContext.containerView;
    
    [destination beginAppearanceTransition:YES animated:YES];
    
    NSTimeInterval transitionDuration = [self transitionDuration:transitionContext];
    UIColor *prevColor = self.player.imageView.backgroundColor;
    self.player.imageView.backgroundColor = [UIColor blackColor];
    self.player.imageView.hidden = NO;
    
    CGPoint imageViewPoint = [self.player.imageView convertPoint:self.player.imageView.frame.origin fromView:nil];
    
    CGRect imageViewRect = CGRectMake(imageViewPoint.x, imageViewPoint.y, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    self.fullScreeFrame = imageViewRect;
    
    [UIView animateKeyframesWithDuration:transitionDuration delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:1.0 animations:^{
            self.player.imageView.frame = imageViewRect;
        }];
    } completion:^(BOOL finished) {
        self.player.imageView.backgroundColor = prevColor;
        [container addSubview:destination.view];
        [destination endAppearanceTransition];
        self.player.imageView.frame = self.originFrame;
        [transitionContext completeTransition:finished];
    }];
}

@end
