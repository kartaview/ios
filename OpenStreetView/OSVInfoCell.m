//
//  OSVInfoCell.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 06/07/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVInfoCell.h"

@interface OSVInfoCell ()

@end

@implementation OSVInfoCell

- (void)prepareForReuse {
    self.imagesInfo.text = @"-";
    self.tracksInfo.text = @"-";
    self.distanceInfo.text = @"-";
    self.OBDInfo.text = @"-";
}

@end
