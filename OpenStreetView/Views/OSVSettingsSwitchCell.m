//
//  OSVSettingsSwitchCell.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 09/11/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import "OSVSettingsSwitchCell.h"

@implementation OSVSettingsSwitchCell

- (IBAction)didToggleSwitch:(UISwitch *)sender {
    if (self.toggleBlock) {
        self.toggleBlock(sender.on);
    }
}

@end
