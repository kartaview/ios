//
//  OSVPushTransition.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 11/10/2016.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVPushTransition.h"
#import "OSVLocalTracksViewController.h"

@interface OSVPushTransition ()

@property (nonatomic, assign) BOOL animatingSource;

@end

@implementation OSVPushTransition

- (instancetype)initWithoutAnimatingSource:(BOOL)animatingSource {
    self = [super init];
    if (self) {
        self.animatingSource = animatingSource;
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.animatingSource = NO;
    }
    return self;
}


- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.5;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    UIViewController *source = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *destination = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *container = transitionContext.containerView;
    
    UIImageView *screenShot = [[UIImageView alloc] initWithImage:[self imageWithView:source.navigationController.navigationBar]];
    screenShot.frame = source.navigationController.navigationBar.frame;
    
    UIView *imag = [[UIView alloc] initWithFrame:CGRectMake(0, 0, source.navigationController.navigationBar.frame.size.width, CGRectGetMaxY(source.navigationController.navigationBar.frame))];
    imag.clipsToBounds = YES;

    [container addSubview:imag];

    [container addSubview:destination.view];
    [destination beginAppearanceTransition:YES animated:YES];
    [destination.view setNeedsLayout];
    [destination.view layoutIfNeeded];
    
    float origin = CGRectGetMaxY(source.navigationController.navigationBar.frame);
    CGRect frameOriginal = CGRectMake(source.view.frame.origin.x, origin, source.view.frame.size.width, [UIScreen mainScreen].bounds.size.height - origin);

    destination.view.frame = CGRectOffset(destination.view.frame, 0, destination.view.frame.size.height);
    source.navigationController.navigationBar.frame = CGRectOffset(source.navigationController.navigationBar.frame, 0, -60);
    NSTimeInterval transitionDuration = [self transitionDuration:transitionContext];

    [UIView animateKeyframesWithDuration:transitionDuration delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.4 animations:^{
            if (!self.animatingSource) {
                source.view.frame = CGRectOffset(source.view.frame, 0, 200);
                imag.frame = CGRectOffset(imag.frame, 0, -imag.frame.size.height-20);
            }
        }];
        [UIView addKeyframeWithRelativeStartTime:0.4 relativeDuration:0.7 animations:^{
            destination.view.frame = frameOriginal;
        }];
        [UIView addKeyframeWithRelativeStartTime:0.2 relativeDuration:0.9 animations:^{
           source.navigationController.navigationBar.frame = CGRectOffset(source.navigationController.navigationBar.frame, 0, 60);
        }];

    } completion:^(BOOL finished) {
        if (!self.animatingSource) {
            source.view.frame = CGRectOffset(source.view.frame, 0, -200);
        }
        [imag removeFromSuperview];
        [destination endAppearanceTransition];
        [transitionContext completeTransition:finished];
    }];
}

- (UIImage *)imageWithView:(UIView *)view {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0f);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO];
    UIImage * snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return snapshotImage;
}

@end
