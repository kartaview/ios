//
//  OSVSegmentedViewCell.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 18/02/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVSegmentedViewCell.h"

@implementation OSVSegmentedViewCell

- (IBAction)didToggleSwitch:(UISegmentedControl *)sender {
    if (self.toggleBlock) {
        self.toggleBlock(sender.selectedSegmentIndex);
    }
}


@end
