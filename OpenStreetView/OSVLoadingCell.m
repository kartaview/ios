//
//  OSVLoadingCell.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 13/10/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import "OSVLoadingCell.h"

@implementation OSVLoadingCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)prepareForReuse {
    [self.activityIndicator stopAnimating];
    self.title.hidden = NO;
    self.subTitle.hidden = NO;
}

@end
