//
//  OSVMainViewController.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 05/07/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVMainViewController.h"
#import "OSVLeftMenuViewController.h"

@interface OSVMainViewController ()

@property (strong, nonatomic) OSVLeftMenuViewController *leftViewController;

@end


@implementation OSVMainViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!self.leftViewController) {
        [self setupWithPresentationStyle:LGSideMenuPresentationStyleSlideAbove];
    }
}

- (void)setupWithPresentationStyle:(LGSideMenuPresentationStyle)style {
    
    UINavigationController *navController = [self.storyboard instantiateViewControllerWithIdentifier:@"NavigationController"];
    self.rootViewController = navController;
    
    self.leftViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"LeftViewController"];
    self.leftViewController.mainMenuDelegate = self;
    //defaultViewController is OSVMapViewController
    self.leftViewController.defaultViewController = navController.viewControllers[0];
    
    // -----
    [self setLeftViewEnabledWithWidth:250.f
                    presentationStyle:style
                 alwaysVisibleOptions:LGSideMenuAlwaysVisibleOnNone];
    
    self.leftViewStatusBarStyle = UIStatusBarStyleDefault;
    self.leftViewStatusBarVisibleOptions = LGSideMenuStatusBarVisibleOnAll;

    // -----
    self.leftViewBackgroundColor = [UIColor colorWithWhite:1.f alpha:0.9];
    
    self.leftViewController.tableView.backgroundColor = [UIColor clearColor];
    // -----
    self.rightViewBackgroundColor = [UIColor colorWithWhite:1.f alpha:0.9];
    
    [self.leftViewController.tableView reloadData];
    [self.leftView addSubview:_leftViewController.view];
}

- (void)leftViewWillLayoutSubviewsWithSize:(CGSize)size {
    [super leftViewWillLayoutSubviewsWithSize:size];
    self.leftViewController.view.frame = CGRectMake(0.f, 0.f, size.width, size.height);
}

@end
