//
//  OSVPopTransition.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 11/10/2016.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVPopTransition.h"

@interface OSVPopTransition ()

@property (nonatomic, assign) BOOL animatingSource;

@end

@implementation OSVPopTransition

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
    
    destination.view.frame = CGRectMake(source.view.frame.origin.x, source.view.frame.origin.y, source.view.frame.size.width, source.view.frame.size.height-40);
    [container insertSubview:destination.view belowSubview:source.view];
    
    UIView *imag = [[UIView alloc] initWithFrame:CGRectMake(0, 0, source.navigationController.navigationBar.frame.size.width, CGRectGetMaxY(source.navigationController.navigationBar.frame))];
    imag.clipsToBounds = YES;
    
    UIImage *navImage = [self imageWithView:destination.navigationController.navigationBar];
    UIImageView *nav = [[UIImageView alloc] initWithImage:navImage];
    nav.frame = source.navigationController.navigationBar.frame;
    imag.backgroundColor = [self getColorFromImage:navImage];
    
    [imag addSubview:nav];
    
    UIWindow *currentWindow = [UIApplication sharedApplication].keyWindow;
    [currentWindow addSubview:imag];
    
    float origin = CGRectGetMaxY(source.navigationController.navigationBar.frame);
    
    CGRect frameOriginal = CGRectMake(source.view.frame.origin.x, origin, source.view.frame.size.width, [UIScreen mainScreen].bounds.size.height - origin);

    if (!self.animatingSource) {
        destination.view.frame = CGRectMake(destination.view.frame.origin.x, 300, destination.view.frame.size.width, destination.view.frame.size.height);
        source.navigationController.navigationBar.frame = CGRectOffset(source.navigationController.navigationBar.frame, 0, -60);

    }

    NSTimeInterval transitionDuration = [self transitionDuration:transitionContext];
    
    [UIView animateKeyframesWithDuration:transitionDuration delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.7 animations:^{
            source.view.frame = CGRectOffset(source.view.frame, 0, source.view.frame.size.height);
            imag.frame = CGRectOffset(imag.frame, 0, -imag.frame.size.height);
        }];
        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.7 animations:^{
            destination.view.frame = frameOriginal;
        }];
        [UIView addKeyframeWithRelativeStartTime:0.2 relativeDuration:0.9 animations:^{
            if (!self.animatingSource) {
                source.navigationController.navigationBar.frame = CGRectOffset(source.navigationController.navigationBar.frame, 0, 60);
            }
        }];
        
    } completion:^(BOOL finished) {

        source.view.frame = CGRectOffset(source.view.frame, 0, -source.view.frame.size.height);

        [imag removeFromSuperview];
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

- (UIColor *)getColorFromImage:(UIImage *)image {
    
    CFDataRef pixelData = CGDataProviderCopyData(CGImageGetDataProvider(image.CGImage));
    const UInt8* data = CFDataGetBytePtr(pixelData);

    int pixelInfo = ((image.size.width  * 1) + 1 ) * 4; // The image is png

    UInt8 red = data[pixelInfo + 2];         // If you need this info, enable it
    UInt8 green = data[(pixelInfo + 1)]; // If you need this info, enable it
    UInt8 blue = data[pixelInfo];    // If you need this info, enable it
    UInt8 alpha = data[pixelInfo + 3];     // I need only this info for my maze game
    CFRelease(pixelData);

    return [UIColor colorWithRed:red/255.0f green:green/255.0f blue:blue/255.0f alpha:alpha/255.0f]; // The pixel color info
}

@end
