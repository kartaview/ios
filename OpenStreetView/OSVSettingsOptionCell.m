//
//  OSVSettingsOptionCell.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 12/07/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVSettingsOptionCell.h"
#import "UIColor+OSVColor.h"

@interface OSVSettingsOptionCell ()

@property (weak, nonatomic) IBOutlet UIImageView *activeCheck;

@end

@implementation OSVSettingsOptionCell

- (void)setIsActive:(BOOL)isActive {
    _isActive = isActive;
    self.activeCheck.hidden = !isActive;
    
    if (isActive) {
        self.optionTitle.textColor = [UIColor hex019ED3];
    } else {
        self.optionTitle.textColor = [UIColor hex1B1C1F];
    }
}

@end
