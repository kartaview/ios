//
//  OSVBaseUser+OSM.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 23/11/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import "OSVBaseUser+OSM.h"

@implementation OSVBaseUser (OSM)

+ (instancetype)baseUserWithOSMUser:(OSMUser *)user {
    OSVBaseUser *baseUser = [OSVBaseUser new];
    baseUser.name = user.name;
    baseUser.type = @"osm";
    baseUser.userID = user.userID;
    
    baseUser.key = user.key;
    baseUser.secret = user.secret;
    
    return baseUser;
}

@end
