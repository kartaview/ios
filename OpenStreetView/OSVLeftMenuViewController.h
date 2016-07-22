//
//  OSVLeftMenuViewController.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 05/07/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OSVLeftMenuViewController : UIViewController

@property (weak, nonatomic) id mainMenuDelegate;
//the first view controller visible on the screen
@property (weak, nonatomic) id defaultViewController;

@property (weak, nonatomic) IBOutlet UITableView    *tableView;
// the title on the middle of the menu
@property (weak, nonatomic) IBOutlet UILabel        *titleButton;

@end
