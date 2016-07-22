//
//  OSVUser.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 23/11/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OSVUser <NSObject>

@property (nonatomic, assign) NSInteger userID;
@property (nonatomic, strong) NSString  *name;
@property (nonatomic, strong) NSString  *type;

@property (nonatomic, assign) double    totalKM;
@property (nonatomic, assign) double    obdDistance;
@property (nonatomic, assign) NSInteger totalPhotos;
@property (nonatomic, assign) NSInteger totalTracks;
@property (nonatomic, assign) NSInteger weekRank;
@property (nonatomic, assign) NSInteger rank;

@property (nonatomic, strong) NSString  *key;
@property (nonatomic, strong) NSString  *secret;

@property (nonatomic, strong) NSString  *accessToken;

@end


@interface OSVUser : NSObject <OSVUser>

@end