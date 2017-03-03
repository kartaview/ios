//
//  OSVTipView.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 25/04/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVTipView.h"
#import "OSVTipPageViewController.h"
#import "OSVIntroViewController.h"
#import "UIColor+OSVColor.h"

@interface OSVTipView () <UIScrollViewDelegate>

@property (strong, nonatomic) NSArray<NSString *>       *tips;
@property (strong, nonatomic) NSArray<NSString *>       *specialTips;
@property (strong, nonatomic) NSArray<NSString *>       *tipTitles;
@property (strong, nonatomic) NSArray<NSString *>       *specialTipsTitle;
@property (strong, nonatomic) NSArray<UIImage *>        *imageNames;

@property (strong, nonatomic) NSTimer                   *timer;

@property (assign, nonatomic) NSInteger                 currentPage;
@property (assign, nonatomic) NSInteger                 previousPage;

@property (assign, nonatomic) BOOL                      manualyChanged;

@property (weak, nonatomic) IBOutlet UIScrollView       *scrollView;

@property (nonatomic, strong) NSMutableArray            *pages;
@property (nonatomic, strong) NSArray                   *tipColors;

@property (weak, nonatomic) IBOutlet UIButton           *dissmissButton;

@property (weak, nonatomic) IBOutlet UIPageControl      *pageControl;

@property (nonatomic, assign) NSInteger                 controlerType;

@end

@implementation OSVTipView

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self prepareWalkthrough];
    }
    
    return self;
}

- (id)viewControllerAtIndex:(NSUInteger)index {
    
    if (!self.controlerType) {
        OSVTipPageViewController *childViewController = [[OSVTipPageViewController alloc] initWithNibName:@"OSVTipPageViewController" bundle:nil];
        childViewController.index = index;
        childViewController.view.backgroundColor = self.tipColors[index];
        
        return childViewController;
    } else {
        OSVIntroViewController *childViewController = [[OSVIntroViewController alloc] initWithNibName:@"OSVIntroViewController" bundle:nil];
        childViewController.index = index;
        childViewController.view.backgroundColor = self.tipColors[index];
        
        return childViewController;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (!UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
        self.pageControl.numberOfPages = self.specialTips.count;
        self.scrollView.contentSize = CGSizeMake(self.frame.size.width * self.specialTips.count, self.frame.size.height);
    } else {
        self.pageControl.numberOfPages = self.tips.count;
        self.scrollView.contentSize = CGSizeMake(self.frame.size.width * self.tips.count, self.frame.size.height);
    }
    
    for (int i = 0; i < self.pages.count; i++) {
        OSVTipPageViewController *vc = self.pages[i];
        vc.view.frame = CGRectMake(i * self.frame.size.width, 0, self.frame.size.width, self.frame.size.height);
        
        if (!UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
            vc.tipDescriptionLabel.text = self.specialTips[i];
            vc.tipTitleLabel.text = self.specialTipsTitle[i];
        } else if (i < self.tips.count) {
            vc.tipDescriptionLabel.text = self.tips[i];
            vc.tipTitleLabel.text = self.tipTitles[i];
        }
        
        if ([vc isKindOfClass:[OSVIntroViewController class]]) {
            ((OSVIntroViewController *)vc).image.image = self.imageNames[i];
        }
    }
}

#pragma mark - Public methods

- (void)randomize {
    NSMutableArray *array = [NSMutableArray array];
    int i = rand()%self.tips.count;
    
    for (int j = i; j < self.tips.count; j++) {
        [array addObject:self.tips[j]];
    }
    
    for (int j = i; j >= 0; j--) {
        [array addObject:self.tips[j]];
    }
    
    self.tips = array;
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    self.pageControl.currentPage = scrollView.contentOffset.x / self.frame.size.width;
    NSInteger count = self.tips.count;
    
    if (!UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
        count = self.specialTips.count;
    }

    if (self.pageControl.currentPage >= count - 1) {
        [self shouldDissmiss:self];
    }
    self.backgroundColor = self.tipColors[self.pageControl.currentPage];
}

- (IBAction)shouldDissmiss:(id)sender {
    BOOL isDissmissed = NO;
    if (self.willDissmiss) {
        isDissmissed = self.willDissmiss();
    }
    
    if (!isDissmissed) {
        [UIView animateWithDuration:0.6 animations:^{
            self.alpha = 0;
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
            
            self.scrollView.contentOffset = CGPointMake(0, 0);
            self.alpha = 1;
            if (self.didDissmiss) {
                self.didDissmiss();
            }
        }];
    } else {
        if (self.didDissmiss) {
            self.didDissmiss();
        }
    }
}

- (void)prepareWalkthrough {
    self.controlerType = 0;

    self.tips = @[NSLocalizedString(@"You will get more points when the streets you're driving have less coverage. Get 10X for a new street in OpenStreetCam!", @""),
                  NSLocalizedString(@"Check that the front hood of the car and the phone’s mount are not visible in the pictures.", @""),
                  NSLocalizedString(@"Try to keep your car’s windshield clean.", @""),
                  NSLocalizedString(@"You can tap on screen to focus. Long press locks it.", @""),
                  NSLocalizedString(@"", @"")];
    self.tipTitles = @[NSLocalizedString(@"Points", @""),
                       NSLocalizedString(@"Phone mount", @""),
                       NSLocalizedString(@"Windshield", @""),
                       NSLocalizedString(@"Camera Focus", @""),
                       NSLocalizedString(@"", @"")];
    
    self.tipColors = @[[UIColor colorWithHex:0x019ED3],
                       [UIColor colorWithHex:0xe7a200],
                       [UIColor colorWithHex:0xBD10E0],
                       [UIColor colorWithHex:0x1DAA63],
                       [UIColor colorWithHex:0x1DAA63],
                       [UIColor colorWithHex:0x1DAA63],
                       [UIColor colorWithHex:0x1DAA63],
                       [UIColor colorWithHex:0x1DAA63]];
    
    self.specialTips = @[NSLocalizedString(@"You will get more points when the streets you're driving have less coverage. Get 10X for a new street in OpenStreetCam!", @""),
                         NSLocalizedString(@"Record in landscape mode to capture better images. Turn your phone if possible.", @""),
                         NSLocalizedString(@"Check that the front hood of the car and the phone’s mount are not visible in the pictures.", @""),
                         NSLocalizedString(@"Try to keep your car’s windshield clean.", @""),
                         NSLocalizedString(@"You can tap on screen to focus. Long press locks it.", @""),
                         NSLocalizedString(@"", @"")];
    
    self.specialTipsTitle = @[NSLocalizedString(@"Points", @""),
                              NSLocalizedString(@"Landscape", @""),
                              NSLocalizedString(@"Phone mount", @""),
                              NSLocalizedString(@"Windshield", @""),
                              NSLocalizedString(@"Camera Focus", @""),
                              NSLocalizedString(@"", @"")];
    self.dissmissButton.hidden = NO;
}

- (void)prepareIntro {
    self.controlerType = 1;
    
    self.tips = @[NSLocalizedString(@"You’re now joining a great community of people that contribute to a free and open platform for street imagery.\n\nBy detecting street features from your photos we can build the best map in the world, together!", @""),
                  NSLocalizedString(@"Use your phone to record the streets you drive, bike or walk, the app will take photos automatically and upload when Wi-Fi is available.", @""),
                  NSLocalizedString(@"Contribute your recordings, gain points and increase your ranking in the OpenStreetCam leaderboard.\n\nTip: Find streets that are not yet covered for many bonus points!", @""),
                  NSLocalizedString(@"", @"")];
    self.tipTitles = @[NSLocalizedString(@"Welcome to OpenStreetCam!", @""),
                       NSLocalizedString(@"How do I contribute?", @""),
                       NSLocalizedString(@"Make it count", @""),
                       NSLocalizedString(@"", @"")];
    
    self.tipColors = @[[UIColor colorWithHex:0x019ED3],
                       [UIColor colorWithHex:0x0fab60],
                       [UIColor colorWithHex:0xe7a200],
                       [UIColor colorWithHex:0xe7a200],
                       [UIColor colorWithHex:0xe7a200],
                       [UIColor colorWithHex:0xe7a200],
                       [UIColor colorWithHex:0xe7a200]];
    
    self.specialTips = self.tips;
    self.specialTipsTitle = self.tipTitles;
    
    self.imageNames = @[[UIImage imageNamed:@"windyRoadLineTall"],
                        [UIImage imageNamed:@"windyRoadLineTall-1"],
                        [UIImage imageNamed:@"windyRoadLineTall-2"],
                        [UIImage new]];
    self.dissmissButton.hidden = YES;
}

- (void)configureViews {
    self.pages = [NSMutableArray array];
    
    for (int i = 0; i < self.specialTips.count; i++) {
        UIViewController *initialViewController = [self viewControllerAtIndex:i];
        [self.pages addObject:initialViewController];
        [self.scrollView addSubview:initialViewController.view];
    }
    
    self.scrollView.contentSize = CGSizeMake(self.frame.size.width * self.tips.count, self.frame.size.height);
    self.pageControl.numberOfPages = self.tips.count;
    self.scrollView.delegate = self;
}

@end
