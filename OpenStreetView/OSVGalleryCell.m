//
//  OSVGalleryCell.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 03/12/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import "OSVGalleryCell.h"

@implementation OSVGalleryCell

- (void)awakeFromNib {
    self.transparentOverlay.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6];
}

- (void)setIsInEditMode:(BOOL)isInEditMode {
    _isInEditMode = isInEditMode;
    self.transparentOverlay.hidden = !isInEditMode;
}

- (void)prepareForReuse {
    self.isInEditMode = NO;
}

@end
