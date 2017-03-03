//
//  OSVUser.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 23/11/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSVGamificationInfo.h"

@protocol OSVUser <NSObject>
//user info
@property (nonatomic, strong) NSString  *userID;
@property (nonatomic, strong) NSString  *name;
@property (nonatomic, strong) NSString  *fullName;
//
@property (nonatomic, assign) double    totalKM;
@property (nonatomic, assign) double    obdDistance;
//
@property (nonatomic, assign) NSInteger totalPhotos;
@property (nonatomic, assign) NSInteger totalTracks;
//rankings
@property (nonatomic, assign) NSInteger weekRank;
@property (nonatomic, assign) NSInteger rank;
//login credentials
@property (nonatomic, strong) NSString  *providerKey;
@property (nonatomic, strong) NSString  *providerSecret;
@property (nonatomic, strong) NSString  *provider;

@property (nonatomic, strong) NSString  *accessToken;

@property (nonatomic, strong) OSVGamificationInfo *gameInfo;

@end


@interface OSVUser : NSObject <OSVUser>

@end
