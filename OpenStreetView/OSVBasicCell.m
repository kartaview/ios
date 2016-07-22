//
//  OSVBasicCell.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 12/07/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVBasicCell.h"

@implementation OSVBasicCell

- (void)prepareForReuse {
    [super prepareForReuse];
    self.titleLabel.text = @"";
    self.rightText.text = @"";
}

@end
