//
//  HNOSMAPI.m
//  HouseNumbers
//
//  Created by BogdanB on 11/08/15.
//  Copyright (c) 2015 skobbler. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OSMAPI.h"
#import "AFOAuth1Client.h"
#import "OSMParser.h"
#import "AFXMLRequestOperation.h"
#import <GameplayKit/GameplayKit.h>

#define kOSMCredentials @"OSMCredentials"
#define kOSMKey         @"OSMKey"
#define kOSMSecret      @"OSMSecret"

#define kOSMAPIBaseURL  @"http://www.openstreetmap.org"

#define kOSMAPITokenRequestPath @"/oauth/request_token/"
#define kOSMAPIUserInfoPath     @"/api/0.6/user/details"
#define kOSMAPICreateChangeset  @"/api/0.6/changeset/create"
#define kOSMAPIChangeset        @"/api/0.6/changeset/"
#define kOSMAPICreateNode       @"/api/0.6/node/create"

#define kSignUpURL              @"http://openstreetmap.org/user/new"

#define kCredentialsID          @"osmLoginCredentials"
#define kOSMUsernameKey         @"OSMUsernameKey"
#define kOSMUserIdKey           @"OSMUserIdKey"

@protocol OSMAPIDelegate;

@interface OSMAPI()

@property (nonatomic, strong) AFOAuth1Client *osmClient;

@end

@implementation OSMAPI

+ (instancetype)sharedInstance {
    static OSMAPI *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[OSMAPI alloc] init];
    });
    
    return instance;
}

- (id)init {
    self = [super init];
    if (self) {
        NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
        NSDictionary *credentials = infoDict[kOSMCredentials];
        NSString *key = credentials[kOSMKey];
        NSString *secret = credentials[kOSMSecret];
        
        self.osmClient = [[AFOAuth1Client alloc] initWithBaseURL:[NSURL URLWithString:kOSMAPIBaseURL] key:key secret:secret];
		self.osmClient.accessToken = [AFOAuth1Token retrieveCredentialWithIdentifier:kCredentialsID];
		
        [self.osmClient registerHTTPOperationClass:[AFHTTPRequestOperation class]];
        [AFXMLRequestOperation addAcceptableContentTypes:[NSSet setWithObjects:@"text/xml", @"application/xml", nil]];
    }
    
    return self;
}

#pragma mark - Public methods

- (BOOL)isAuthorized {
	return ([self userName] &&
			[self userID] &&
			[self userKey] &&
			[self userSecret]);
}

- (OSMUser *)osmUser {

	if ([self isAuthorized]) {
		OSMUser *user = [OSMUser new];
		user.userID = [self userID];
		user.name = [self userName];
		user.providerKey = [self userKey];
		user.providerSecret = [self userSecret];
		user.provider = @"osm";
		
		return user;
	}
	
	return nil;
}

- (void)logIn {
    [self authorize];
}

- (BOOL)logout {
	BOOL couldDelete = [AFOAuth1Token deleteCredentialWithIdentifier:kCredentialsID];
	if (couldDelete) {
		NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
		NSDictionary *credentials = infoDict[kOSMCredentials];
		NSString *key = credentials[kOSMKey];
		NSString *secret = credentials[kOSMSecret];
		self.osmClient = [[AFOAuth1Client alloc] initWithBaseURL:[NSURL URLWithString:kOSMAPIBaseURL] key:key secret:secret];
	}
	
	return couldDelete;
}

- (void)signUp {
    NSURL *signUpUrl = [NSURL URLWithString:kSignUpURL];
    if ([[UIApplication sharedApplication] canOpenURL:signUpUrl]) {
        [[UIApplication sharedApplication] openURL:signUpUrl];
    }
}

- (AFOAuth1Token *)osmAccessToken {
    return self.osmClient.accessToken;
}
	
#pragma mark - Private methods

- (void)authorize {
    [self.osmClient authorizeUsingOAuthWithRequestTokenPath:kOSMAPITokenRequestPath userAuthorizationPath:@"/oauth/authorize" callbackURL:[NSURL URLWithString:@"osmLogin://success"] accessTokenPath:@"/oauth/access_token" accessMethod:@"GET" scope:nil presentation:^(UIViewController *vc) {
        UIViewController *mainController = [UIApplication sharedApplication].keyWindow.rootViewController;
        [mainController presentViewController:vc animated:YES completion:^{
            
        }];
    } success:^(AFOAuth1Token *accessToken, id responseObject) {
        self.osmClient.accessToken = accessToken;
        [self requestAccountInfo];
    } failure:^(NSError *error) {
        if (self.didFinishLogin) {
            self.didFinishLogin(nil, NO);
        }
        
        NSLog(@"Auth error: %@", error);
    }];
}

- (void)requestAccountInfo{
    [self.osmClient registerHTTPOperationClass:[AFXMLRequestOperation class]];
    [self.osmClient getPath:kOSMAPIUserInfoPath parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        OSMParser *parser = [[OSMParser alloc] init];
        [parser parseWithData:responseObject andCompletionHandler:^(OSMUser *user) {
            user.providerKey = self.osmClient.accessToken.key;
            user.providerSecret = self.osmClient.accessToken.secret;
            
            if (self.didFinishLogin) {
                self.didFinishLogin(user, YES);
            }
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (self.didFinishLogin) {
            self.didFinishLogin(nil, NO);
        }

        NSLog(@"Account info request error: %@", error);
    }];
}

- (NSString *)userName {
	return self.osmClient.accessToken.userInfo[kOSMUsernameKey];
}

- (NSInteger)userID {
	return ((NSNumber *)self.osmClient.accessToken.userInfo[kOSMUserIdKey]).integerValue;
}

- (NSString *)userKey {
	return self.osmClient.accessToken.key;
}

- (NSString *)userSecret {
	return self.osmClient.accessToken.secret;
}
	
@end
