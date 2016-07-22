//
//  RLMPhoto.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 14/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import "RLMPhoto.h"

@implementation RLMPhoto

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.addressName = @"";
    }
    return self;
}

+ (NSString *)primaryKey {
    return @"localPhotoID";
}

@end
