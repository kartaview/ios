//
//  OSVButton.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 26/11/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import "OSVButton.h"
#import "UIColor+OSVColor.h"

@interface OSVButton ()


@end

@implementation OSVButton

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    
    if (self.selected) {
        return;
    }
    
    if (highlighted) {
        self.backgroundColor = [UIColor hex03A9F4];
    } else {
        self.backgroundColor = [UIColor whiteColor];
    }
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    
    if (selected) {
        self.backgroundColor = [UIColor hex03A9F4];
    } else {
        self.backgroundColor = [UIColor whiteColor];
    }
}

@end
