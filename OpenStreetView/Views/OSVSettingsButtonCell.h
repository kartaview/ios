//
//  OSVSettingsButtonCell.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 23/03/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OSVSettingsButtonCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet UIButton *button;

@property (copy, nonatomic) void (^actionBlock)(UIButton *button);

@end
