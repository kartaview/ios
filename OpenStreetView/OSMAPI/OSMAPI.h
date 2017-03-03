//
//  OSMAPI.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 14/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSMUser.h"

#define kOSCCredentialsID		@"kOSCCredentialsID"
#define kOSCAuthProvider        @"kOSCAuthProvider"

@protocol OSMAPIDelegate;
@class AFOAuth1Token;

@interface OSMAPI : NSObject

@property (nonatomic, copy) void (^didFinishLogin)(OSMUser *user, BOOL success);

#pragma mark Initialization
+ (instancetype)sharedInstance;

#pragma mark Authorization
- (void)logIn;
- (BOOL)logout;
- (void)signUp;

- (BOOL)isAuthorized;

- (OSMUser *)osmUser;
- (AFOAuth1Token *)osmAccessToken;

@end
