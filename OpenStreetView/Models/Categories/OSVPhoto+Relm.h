//
//  OSMPhoto+Relm.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 15/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import "OSVPhoto.h"
#import "RLMPhoto.h"

@interface OSVPhoto (Relm)

- (RLMPhoto *)toRealmObject;
+ (OSVPhoto *)fromRealmObject:(RLMPhoto *)photoObject;

@end
