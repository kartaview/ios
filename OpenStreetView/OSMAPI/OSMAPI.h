//
//  OSMAPI.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 14/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSMUser.h"

#define kCredentialsID          @"osmLoginCredentials"
#define kOSMUsernameKey         @"OSMUsernameKey"
#define kOSMUserIdKey           @"OSMUserIdKey"

@protocol OSMAPIDelegate;
@class AFOAuth1Token;

@interface OSMAPI : NSObject

@property (nonatomic, copy) void (^didFinishLogin)(OSMUser *user, BOOL success);
@property (nonatomic, assign, readonly, getter = isAuthorized) BOOL authorized;

#pragma mark Initialization
+ (instancetype)sharedInstance;

#pragma mark Authorization
- (void)logIn;
- (BOOL)logout;
- (void)signUp;

- (OSMUser *)osmUser;
- (AFOAuth1Token *)osmAccessToken;

@end
