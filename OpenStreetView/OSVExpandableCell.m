//
//  OSVExpandableCell.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 18/11/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import "OSVExpandableCell.h"

@implementation OSVExpandableCell

- (void)awakeFromNib {
    [super awakeFromNib];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(expandSection:)];
    tapGesture.numberOfTapsRequired = 1;
    
    [self.contentView addGestureRecognizer:tapGesture];
}


- (void)expandSection:(id)sender {
    self.action(self);
}

@end
