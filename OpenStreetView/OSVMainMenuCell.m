//
//  OSVMainMenuCell.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 05/07/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVMainMenuCell.h"

@interface OSVMainMenuCell ()

@property (weak, nonatomic) IBOutlet UIView *activeView;

@end

@implementation OSVMainMenuCell


- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.active = NO;
        self.title.text = @"";
    }
    
    return self;
}

- (void)setActive:(BOOL)active {
    _active = active;
    self.activeView.hidden = !active;
}

@end
