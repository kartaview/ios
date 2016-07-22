//
//  OSVRedButton.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 27/11/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import "OSVRedButton.h"
#import "UIColor+OSVColor.h"

@implementation OSVRedButton

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    
    if (highlighted) {
        self.backgroundColor = [UIColor whiteColor];
    } else {
        self.backgroundColor = [UIColor hexF44336];
    }
}

@end
