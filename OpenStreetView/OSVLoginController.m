//
//  OSVLoginController.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 23/06/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//


#import "OSVLoginController.h"

#define kOSCUsernameKey         @"OSCUsernameKey"
#define kOSCUserIdKey           @"OSCUserIdKey"
#define kOSCTokenKey			@"kOSCTokenKey"

#define kOSVTokenKey			@"kOSVTokenKey"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

#import <GoogleSignIn/GoogleSignIn.h>

#import "OSVAPI.h"
#import "OSMAPI.h"
#import "AFOAuth1Client.h"
#import "OSVBaseUser.h"

@interface OSVLoginController ()

@property (nonatomic, strong) OSVAPI            *osvAPI;

@end

@implementation OSVLoginController

- (instancetype)init {
        self = [super init];
        if (self) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSignInWithGoogle:) name:@"kOSVGoogleSignIn" object:nil];
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSignInWithFacebook:) name:@"kOSVFacebookSignIn" object:nil];
        }
        return self;
}
    
- (instancetype)initWithOSVAPI:(OSVAPI *)api {
    self = [super init];
    
    if (self) {
        self.osvAPI = api;
    }
    
    return self;
}

- (void)setDidFinishLogin:(void (^)(OSMUser *, BOOL))didFinishLogin {
    [OSMAPI sharedInstance].didFinishLogin = didFinishLogin;
}

- (void (^)(OSMUser *, BOOL))didFinishLogin {
    return [OSMAPI sharedInstance].didFinishLogin;
}

- (void)loginWithPartial:(void (^)(NSError *error))partial andCompletion:(void (^)(NSError *error))completion {
    [[OSMAPI sharedInstance] logIn];
    [OSMAPI sharedInstance].didFinishLogin = ^(OSMUser *osmUser, BOOL success){
        NSError *error = nil;
        if (!success) {
            error = [[NSError alloc] initWithDomain:@"OSVLogginControler" code:11 userInfo:@{}];
            completion(error);
            return;
        }
		partial(error);
		
		OSVBaseUser *osvUser = [self baseUserWithOSMUser:osmUser];
		
        [self.osvAPI authenticateUser:osvUser withCompletion:^(NSError *erro) {
            if (!erro) {
								
                AFOAuth1Token *persistentToken = [[OSMAPI sharedInstance] osmAccessToken];
                persistentToken.userInfo = @{kOSCUsernameKey : osvUser.name,
											 kOSCUserIdKey : osvUser.userID,
											 kOSCTokenKey : osvUser.accessToken,
											 kOSCAuthProvider : @"osm"};
				
                [AFOAuth1Token storeCredential:persistentToken withIdentifier:kOSCCredentialsID];
			} else {
				[[OSMAPI sharedInstance] logout];
			}
				
            completion(erro);
        }];
    };
}

- (void)logout {
    [[OSMAPI sharedInstance] logout];
	[[GIDSignIn sharedInstance] signOut];
	[[FBSDKLoginManager new] logOut];
	[AFOAuth1Token deleteCredentialWithIdentifier:kOSCCredentialsID];
//	[self.osvAPI logOut];
}

- (void)rankingWithCompletion:(void (^)(NSInteger , NSError *))completion {
    [self.osvAPI leaderBoardWithCompletion:^(NSArray *leaderBoard, NSError *error) {
        for (id<OSVUser> user in leaderBoard) {
            if ([user.name isEqualToString:self.oscUser.name]) {
                completion(user.rank, nil);
                return;
            }
        }
    }];
}

- (void)leaderBoardWithCompletion:(void (^)(NSArray *, NSError *))completion {
    [self.osvAPI leaderBoardWithCompletion:completion];
}

- (void)gameLeaderBoardForRegion:(NSString *)countryCode
                        formDate:(NSDate *)date
                  withCompletion:(void (^)(NSArray *, NSError *))completion {
    
    [self.osvAPI gameLeaderBoardForCountry:countryCode
                                  fromDate:date
                           	withCompletion:completion];
}

- (void)osvUserInfoWithCompletion:(void (^)(id<OSVUser> user, NSError *error))completion {
	id<OSVUser> osvuser = self.oscUser;
	
	if (osvuser) {
		[self.osvAPI getUserInfo:osvuser withCompletion:^(id<OSVUser> user, NSError *error) {
			completion(user, error);
		}];
	}
}

- (NSURL *)getAppLink {
    return [self.osvAPI getAppLink];
}

- (void)checkForAppUpdateWithCompletion:(void (^)(BOOL response))completion {
    [self.osvAPI getApiVersionWithCompletion:^(double version, NSError *error) {
        if (!error) {
            completion(version > 0);
        }
    }];
}
    
- (BOOL)userIsLoggedIn {
	return [self oscUser] != nil;
}
    
- (void)didSignInWithGoogle:(NSNotification *)notification {
	if ([self userIsLoggedIn]) {
		return;
	}
	
    GIDGoogleUser *googleUser = notification.userInfo[@"user"];
	OSVBaseUser *user = [self baseUserWithGoogleUser:googleUser];
	
    if (user) {
        [self.osvAPI authenticateUser:user withCompletion:^(NSError * _Nullable error) {
			if (!error) {
				AFOAuth1Token *persistentToken = [AFOAuth1Token new];
				persistentToken.userInfo = @{kOSCUsernameKey : user.name,
											 kOSCUserIdKey : user.userID,
											 kOSCTokenKey : user.accessToken,
											 kOSCAuthProvider : @"google"};
				
				[AFOAuth1Token storeCredential:persistentToken withIdentifier:kOSCCredentialsID];
			} else {
				[[GIDSignIn sharedInstance] signOut];
			}
        }];
    }
}

- (void)didSignInWithFacebook:(NSNotification *)notification {
	if ([self userIsLoggedIn]) {
		return;
	}
	
	FBSDKProfile *profile = notification.userInfo[@"user"];
	OSVBaseUser *user = [self baseUserWithFacebookProfile:profile];
	
	if (user) {
		[self.osvAPI authenticateUser:user withCompletion:^(NSError * _Nullable error) {
			if (!error) {
				AFOAuth1Token *persistentToken = [AFOAuth1Token new];
				persistentToken.userInfo = @{kOSCUsernameKey : user.name,
											 kOSCUserIdKey : user.userID,
											 kOSCTokenKey : user.accessToken,
											 kOSCAuthProvider : @"facebook"};
				
				[AFOAuth1Token storeCredential:persistentToken withIdentifier:kOSCCredentialsID];
			} else {
				[[FBSDKLoginManager new] logOut];
			}
		}];
	}
}

- (OSVBaseUser *)oscUser {
	AFOAuth1Token *thirdPartyAuth = [AFOAuth1Token retrieveCredentialWithIdentifier:kOSCCredentialsID];
	
	OSVBaseUser *user = [OSVBaseUser new];
	user.userID = thirdPartyAuth.userInfo[kOSCUserIdKey];
	user.name = thirdPartyAuth.userInfo[kOSCUsernameKey];
	user.provider = thirdPartyAuth.userInfo[kOSCAuthProvider];
	user.accessToken = thirdPartyAuth.userInfo[kOSCTokenKey];
	
	if ([self validOSCUser:user]) {
		return user;
	}
	
	OSMUser *oldOSMAuth = [OSMAPI sharedInstance].osmUser;
	user.userID = [@(oldOSMAuth.userID) stringValue];
	user.name = oldOSMAuth.name;
	user.provider = oldOSMAuth.provider;
	user.accessToken = [OSMAPI sharedInstance].osmAccessToken.userInfo[kOSVTokenKey];
	
	if ([[OSMAPI sharedInstance] isAuthorized]) {
		return user;
	}
	
	return nil;
}

- (BOOL)validOSCUser:(id<OSVUser>)user {
	return	user.userID && ![user.userID isEqualToString:@""] &&
			user.name && ![user.name isEqualToString:@""] &&
			user.provider && ![user.provider isEqualToString:@""] &&
			user.accessToken && ![user.accessToken isEqualToString:@""];
}

- (OSVBaseUser *)baseUserWithOSMUser:(OSMUser *)osmUser {
	OSVBaseUser *osvUser = [OSVBaseUser new];
	osvUser.providerKey = osmUser.providerKey;
	osvUser.providerSecret = osmUser.providerSecret;
	osvUser.provider = @"osm";
	
	return osvUser;
}
	
- (OSVBaseUser *)baseUserWithGoogleUser:(GIDGoogleUser *)googleUser {
	OSVBaseUser *osvUser = [OSVBaseUser new];
	osvUser.providerKey = googleUser.authentication.accessToken;
	osvUser.provider = @"google";

	return osvUser;
}

- (OSVBaseUser *)baseUserWithFacebookProfile:(FBSDKProfile *)profile {
	OSVBaseUser *osvUser = [OSVBaseUser new];
	osvUser.provider = @"facebook";
	osvUser.providerKey = [FBSDKAccessToken currentAccessToken].tokenString;
	
	return osvUser;
}

@end
