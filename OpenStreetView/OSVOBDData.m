//
//  OSVOBDData.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 23/03/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVOBDData.h"

@implementation OSVOBDData

- (instancetype)init {
    self = [super init];
    if (self) {
        _speed = NSNotFound;
        _timestamp = [[NSDate new] timeIntervalSince1970];
    }
    return self;
}

@end
