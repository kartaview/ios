//
//  OSVDotedPolyline.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 28/06/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVDotedPolyline.h"

@implementation OSVDotedPolyline

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.borderDotsSpacingSize = 25;
        self.borderDotsSize = 25;
        self.lineWidth = 0;
        self.backgroundLineWidth = 14;
    }
    
    return self;
}

@end
