//
//  OSVLoginController.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 23/06/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVLoginController.h"
#import "OSVAPI.h"
#import "OSMAPI.h"
#import "AFOAuth1Client.h"
#import "OSVBaseUser+OSM.h"

#define kOSVTokenKey @"kOSVTokenKey"

@interface OSVLoginController ()

@property (nonatomic, strong) OSVAPI            *osvAPI;

@end

@implementation OSVLoginController

- (instancetype)initWithOSVAPI:(OSVAPI *)api basePath:(NSString *)basePath {
    self = [super init];
    
    if (self) {
        self.osvAPI = api;
        self.basePathToPhotos = basePath;
    }
    
    return self;
}

- (void)setDidFinishLogin:(void (^)(OSMUser *, BOOL))didFinishLogin {
    [OSMAPI sharedInstance].didFinishLogin = didFinishLogin;
}

- (void (^)(OSMUser *, BOOL))didFinishLogin {
    return [OSMAPI sharedInstance].didFinishLogin;
}

- (void)loginWithCompletion:(void (^)(NSError *error))completion {
    [[OSMAPI sharedInstance] logIn];
    [OSMAPI sharedInstance].didFinishLogin = ^(OSMUser *osmUser, BOOL success){
        NSError *error = nil;
        if (!success) {
            error = [[NSError alloc] initWithDomain:@"OSVLogginControler" code:11 userInfo:@{}];
            completion(error);
            return;
        }
        
        OSVBaseUser *osvUser = [OSVBaseUser baseUserWithOSMUser:osmUser];
        [self.osvAPI authenticateUser:osvUser withCompletion:^(NSError *erro) {
            if (!erro) {
                AFOAuth1Token *persistentToken = [[OSMAPI sharedInstance] osmAccessToken];
                persistentToken.userInfo = @{kOSMUsernameKey : osvUser.name, kOSMUserIdKey : @(osvUser.userID), kOSVTokenKey : osvUser.accessToken};
                
                [AFOAuth1Token storeCredential:persistentToken withIdentifier:kCredentialsID];
            }
            
            completion(erro);
        }];
    };
}

- (void)logout {
    [[OSMAPI sharedInstance] logout];
}

- (void)rankingWithCompletion:(void (^)(NSInteger , NSError *))completion {
    [self.osvAPI leaderBoardWithCompletion:^(NSArray *leaderBoard, NSError *error) {
        for (id<OSVUser> user in leaderBoard) {
            if ([user.name isEqualToString:self.user.name]) {
                completion(user.rank, nil);
                return;
            }
        }
    }];
}

- (void)osvUserInfoWithCompletion:(void (^)(id<OSVUser> user, NSError *error))completion {
    [self.osvAPI getUserInfo:self.user withCompletion:^(id<OSVUser> user, NSError *error) {
        completion(user, error);
    }];
}

- (id<OSVUser>)user {
    OSMUser *osmUser = [[OSMAPI sharedInstance] osmUser];
    OSVBaseUser *osvUser = [OSVBaseUser baseUserWithOSMUser:osmUser];
    osvUser.accessToken = [self osvAccessToken];
    
//    TODO  remove this after the authentication is enabled on server 
    if (!osvUser.accessToken) {
        osvUser.accessToken = @"";
    }
    
    return osvUser;
}

- (NSString *)osvAccessToken {
    return [[OSMAPI sharedInstance] osmAccessToken].userInfo[kOSVTokenKey];
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
    id<OSVUser> user = [self user];
    return  user != nil &&
    user.userID != 0 &&
    user.name != nil &&
    ![user.name isEqualToString:@""] &&
    user.accessToken != nil &&
    ![user.accessToken isEqualToString:@""];
}

@end
