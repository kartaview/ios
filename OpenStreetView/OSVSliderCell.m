//
//  OSVSliderCell.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 28/01/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVSliderCell.h"

@implementation OSVSliderCell

- (IBAction)didChangeValue:(UISlider *)sender {
    if (self.didChangeValue) {
        self.didChangeValue(sender);
    }
}

@end
