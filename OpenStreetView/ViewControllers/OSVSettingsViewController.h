//
//  OSVSettingsViewController.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 09/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OSVSettingsViewController : UIViewController

@property (assign, nonatomic) int               obdWIFIConnectionStatus;
@property (assign, nonatomic) int               obdBLEConnectionStatus;

@property (weak, nonatomic) IBOutlet UIButton   *settingsTitle;

- (void)reloadData;
- (void)deselectTableViewCell;

@end
