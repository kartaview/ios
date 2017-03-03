//
//  OSVIntroViewController.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 17/01/2017.
//  Copyright © 2017 Bogdan Sala. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OSVIntroViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel        *tipTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel        *tipDescriptionLabel;
@property (weak, nonatomic) IBOutlet UIImageView    *image;

@property (assign, nonatomic) NSInteger             index;

@end
