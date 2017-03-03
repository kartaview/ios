//
//  OSVNavigationController.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 08/07/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVNavigationController.h"
#import "OSVSplashViewController.h"

@implementation OSVNavigationController


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        OSVSplashViewController *vc = [sb instantiateViewControllerWithIdentifier:@"splashScreenID"];
        vc.view.frame = self.view.frame;
        [self.view addSubview:vc.view];
        [vc animateLogo];
    });
    
}

- (BOOL)prefersStatusBarHidden {
    return self.topViewController ? [self.topViewController prefersStatusBarHidden] : [super prefersStatusBarHidden];
}

- (BOOL)shouldAutorotate {
    return self.topViewController ? [self.topViewController shouldAutorotate] : [super shouldAutorotate];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return self.topViewController ? [self.topViewController supportedInterfaceOrientations] : [super supportedInterfaceOrientations];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.topViewController ? [self.topViewController preferredStatusBarStyle] : [super preferredStatusBarStyle];
}

@end
