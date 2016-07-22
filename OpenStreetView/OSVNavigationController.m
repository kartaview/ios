//
//  OSVNavigationController.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 08/07/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVNavigationController.h"

@implementation OSVNavigationController

- (BOOL)prefersStatusBarHidden {
    return self.topViewController ? [self.topViewController prefersStatusBarHidden] : [super prefersStatusBarHidden];
}

- (BOOL)shouldAutorotate {
    return self.topViewController ? [self.topViewController shouldAutorotate] : [super shouldAutorotate];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return self.topViewController ? [self.topViewController supportedInterfaceOrientations] : [super supportedInterfaceOrientations];
}


@end
