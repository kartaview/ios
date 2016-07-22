//
//  OSVSettingsSwitchCell.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 09/11/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OSVSettingsSwitchCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UISwitch   *onOffSwitch;
@property (weak, nonatomic) IBOutlet UILabel    *titleLable;
@property (weak, nonatomic) IBOutlet UILabel    *subTitleLabel;

@property (copy, nonatomic) void (^toggleBlock)(BOOL value);

@end
