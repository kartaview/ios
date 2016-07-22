//
//  OSVSequenceCell.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 21/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import "OSVSequenceCell.h"

@interface OSVSequenceCell ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *dateLeadingConstrain;

@end

@implementation OSVSequenceCell

- (void)setIsLastCell:(BOOL)isLastCell {
    _isLastCell = isLastCell;
    if (isLastCell) {
        self.dateLeadingConstrain.constant = 0;
    } else {
        self.dateLeadingConstrain.constant = 50;
    }
    [self setNeedsDisplay];
    [self setNeedsUpdateConstraints];
    [self setNeedsLayout];
}

@end
