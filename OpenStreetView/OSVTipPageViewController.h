//
//  OSVTipPageViewController.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 05/05/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OSVTipPageViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *tipTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *tipDescriptionLabel;

@property (assign, nonatomic) NSInteger         index;

@end
