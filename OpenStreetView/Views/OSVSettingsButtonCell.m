//
//  OSVSettingsButtonCell.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 23/03/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVSettingsButtonCell.h"

@interface OSVSettingsButtonCell ()

@property (nonatomic, assign) BOOL isConnected;

@end

@implementation OSVSettingsButtonCell

- (IBAction)didTapButton:(id)sender {
    self.actionBlock(sender);
}

@end
