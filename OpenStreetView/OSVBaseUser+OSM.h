//
//  OSVBaseUser+OSM.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 23/11/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import "OSVBaseUser.h"
#import "OSMUser.h"

@interface OSVBaseUser (OSM)

+ (instancetype)baseUserWithOSMUser:(OSMUser *)user;

@end
