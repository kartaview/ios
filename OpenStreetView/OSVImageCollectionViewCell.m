//
//  OSVImageCollectionViewCell.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 26/11/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import "OSVImageCollectionViewCell.h"
#import "UIColor+OSVColor.h"

#define kSpacing 2

@implementation OSVImageCollectionViewCell

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
        backgroundView.backgroundColor = [UIColor hex0F73C6];
        self.selectedBackgroundView = backgroundView;
        // quick ugly fix
        self.selectedBackgroundView.frame = CGRectInset(self.selectedBackgroundView.frame, -kSpacing, -kSpacing);
        self.selectedBackgroundView.superview.clipsToBounds = NO;
    }
    
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.selected = NO;
}

@end
