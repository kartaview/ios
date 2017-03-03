//
//  OSVPolyline.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 19/02/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVPolyline.h"

@implementation OSVPolyline

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.coverage = 0;
    }
    return self;
}

@end
