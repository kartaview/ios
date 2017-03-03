//
//  OSVSplashViewController.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 07/10/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVSplashViewController.h"

@interface OSVSplashViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *splashImage;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *centerYConstraint;

@end

@implementation OSVSplashViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)animateLogo {
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    
    self.centerYConstraint.constant = -self.view.frame.size.height/5.0;
    
    [UIView animateWithDuration:0.45 animations:^{
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
        
        self.view.alpha = 0;
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
    }];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
