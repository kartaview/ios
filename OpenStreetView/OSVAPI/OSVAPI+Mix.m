//
//  OSVAPI+Mix.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 23/06/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVAPI.h"
#import "OSVUser.h"
#import "OSVAPIUtils.h"

#define kAuthenticateMethod @"auth/openstreetmap/client_auth"
#define kLeaderBoard        @"user/leaderboard/"
#define kUserDetails        @"user/details/"

#define kVersion            @"version"
#define kDownloadApp        @"downloadapp"

@implementation OSVAPI (Login)

- (void)authenticateUser:(id<OSVUser>)user withCompletion:(void (^)(NSError *_Nullable error))completion {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [self.configurator osvBaseURL], kAuthenticateMethod]];
    
    NSString *request_token = user.key;
    NSString *secret_token = user.secret;
    
    AFHTTPRequestOperation *requestOperation = [OSVAPIUtils requestWithURL:url parameters:NSDictionaryOfVariableBindings(request_token, secret_token) method:@"POST"];
    
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (!operation.isCancelled) {
            if (!responseObject) {
                completion([NSError errorWithDomain:@"OSVAPI" code:1 userInfo:@{@"Response":@"NoResponse"}]);
                return;
            }
            
            NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:nil];
            user.accessToken = response[@"osv"][@"access_token"];
            
            completion(nil);
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(error);
    }];
    
    [self.requestsQueue addOperation:requestOperation];
}

- (void)getUserInfo:(id<OSVUser>)user withCompletion:( void (^)(id<OSVUser> user, NSError *error))completion {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@%@", [self.configurator osvBaseURL], [self.configurator osvAPIVerion], kUserDetails]];
    
    NSString *externalUserId = [@(user.userID) stringValue];
    
    AFHTTPRequestOperation *requestOperation = [OSVAPIUtils requestWithURL:url parameters:NSDictionaryOfVariableBindings(externalUserId) method:@"POST"];
    
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (!operation.isCancelled) {
            if (!responseObject) {
                completion(nil, [NSError errorWithDomain:@"OSVAPI" code:1 userInfo:@{@"Response":@"NoResponse"}]);
                return;
            }
            
            NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:nil];
            NSDictionary *userDict = response[@"osv"];
            OSVUser *user = [OSVUser new];
            user.name = userDict[@"username"];
            user.totalKM = [userDict[@"totalDistance"] doubleValue];
            user.obdDistance = [userDict[@"obdDistance"] doubleValue];
            user.rank = [userDict[@"overallRank"] integerValue];
            user.weekRank = [userDict[@"weeklyRank"] integerValue];
            user.totalTracks = [userDict[@"totalTracks"] integerValue];
            user.totalPhotos = [userDict[@"totalPhotos"] integerValue];
            user.type = @"osv";

            completion(user, nil);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(nil, error);
    }];
    
    [self.requestsQueue addOperation:requestOperation];
}

@end

@implementation OSVAPI (Ranking)

- (void)leaderBoardWithCompletion:(void (^)(NSArray *leaderBoard, NSError *error))completion {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@%@", [self.configurator osvBaseURL], [self.configurator osvAPIVerion], kLeaderBoard]];

    AFHTTPRequestOperation *requestOperation = [OSVAPIUtils requestWithURL:url parameters:@{} method:@"POST"];
    
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (!operation.isCancelled) {
            if (!responseObject) {
                completion(nil, [NSError errorWithDomain:@"OSVAPI" code:1 userInfo:@{@"Response":@"NoResponse"}]);
                return;
            }
            
            NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:nil];
            NSArray *osvArray = response[@"osv"];
            
            NSMutableArray *usersArray = [NSMutableArray array];
            int rank = 0;
            for (NSDictionary *userDict in osvArray) {
                rank += 1;
                OSVUser *user = [OSVUser new];
                user.userID = [userDict[@"id"] integerValue];
                user.name = userDict[@"username"];
                user.totalKM = [userDict[@"total_km"] doubleValue];
                user.type = @"osv";
                user.rank = rank;
                
                [usersArray addObject:user];
            }
            
            completion(usersArray, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(nil, error);
    }];
    
    [self.requestsQueue addOperation:requestOperation];
}

@end


@implementation OSVAPI(Version)

- (void)getApiVersionWithCompletion:(void (^)(double version, NSError *error))completion {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [self.configurator osvBaseURL],kVersion]];
    
    AFHTTPRequestOperation *requestOperation = [OSVAPIUtils requestWithURL:url parameters:@{} method:@"POST"];
    
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (!operation.isCancelled) {
            if (!responseObject) {
                completion(0, [NSError errorWithDomain:@"OSVAPI" code:1 userInfo:@{@"Response":@"NoResponse"}]);
                return;
            }
            
            NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:nil];
            double osvVersion = [response[@"version"] floatValue];
            
            completion(osvVersion, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(0, error);
    }];
    
    [self.requestsQueue addOperation:requestOperation];
}

- (NSURL *)getAppLink {
    NSString *client = @"iOS";
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@?client=%@", [self.configurator osvBaseURL], kDownloadApp, client]];

    return url;
}

@end