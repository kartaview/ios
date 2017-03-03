//
//  OSVIntroViewController.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 17/01/2017.
//  Copyright © 2017 Bogdan Sala. All rights reserved.
//

#import "OSVIntroViewController.h"

@interface OSVIntroViewController ()

@end

@implementation OSVIntroViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
