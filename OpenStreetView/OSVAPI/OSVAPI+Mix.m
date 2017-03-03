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

#define kOSVAuthenticateMethod      @"auth/openstreetmap/client_auth"
#define kGoogleAuthenticateMethod   @"auth/google/client_auth"
#define kFacebookAuthenticateMethod @"auth/facebook/client_auth"

#define kLeaderBoard        @"user/leaderboard/"
#define kgameLeaderBoard    @"gm-leaderboard"

#define kUserDetails        @"user/details/"

#define kVersion            @"version"
#define kDownloadApp        @"downloadapp"

@implementation OSVAPI (Login)

- (void)logOut {
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [self.configurator osvBaseURL], @"logout"]];
	AFHTTPRequestOperation *requestOperation = [OSVAPIUtils requestWithURL:url parameters:[NSDictionary dictionary] method:@"GET"];
	
	[requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
		 if (!operation.isCancelled) {
			 NSLog(@"ok");
		 }
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		NSLog(@"!!!!ok");
	}];
	
	[self.requestsQueue addOperation:requestOperation];
}
	
- (void)authenticateUser:(id<OSVUser>)user withCompletion:(void (^)(NSError *_Nullable error))completion {
	
    AFHTTPRequestOperation *requestOperation = nil;
    
    if ([user.provider isEqualToString:@"osm"]) {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [self.configurator osvBaseURL], kOSVAuthenticateMethod]];
        
        NSString *request_token = user.providerKey;
        NSString *secret_token = user.providerSecret;
        
        requestOperation = [OSVAPIUtils requestWithURL:url parameters:NSDictionaryOfVariableBindings(request_token, secret_token) method:@"POST"];
    } else if ([user.provider isEqualToString:@"google"]) {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [self.configurator osvBaseURL], kGoogleAuthenticateMethod]];
        
        NSString *request_token = user.providerKey;
        
        requestOperation = [OSVAPIUtils requestWithURL:url parameters:NSDictionaryOfVariableBindings(request_token) method:@"POST"];
    } else if ([user.provider isEqualToString:@"facebook"]) {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [self.configurator osvBaseURL], kFacebookAuthenticateMethod]];
        
        NSString *request_token = user.providerKey;
        
        requestOperation = [OSVAPIUtils requestWithURL:url parameters:NSDictionaryOfVariableBindings(request_token) method:@"POST"];
    }

    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (!operation.isCancelled) {
            if (!responseObject) {
                completion([NSError errorWithDomain:@"OSVAPI" code:1 userInfo:@{@"Response":@"NoResponse"}]);
                return;
            }
            
            NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:nil];
            user.accessToken = response[@"osv"][@"access_token"];
			user.userID = response[@"osv"][@"id"];
			user.name = response[@"osv"][@"username"];
			
            completion(nil);
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(error);
    }];
    
    [self.requestsQueue addOperation:requestOperation];
}

- (void)getUserInfo:(id<OSVUser>)user withCompletion:( void (^)(id<OSVUser> user, NSError *error))completion {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@%@", [self.configurator osvBaseURL], [self.configurator osvAPIVerion], kUserDetails]];
    
    NSString *username = user.name;
	
    AFHTTPRequestOperation *requestOperation = [OSVAPIUtils requestWithURL:url parameters:NSDictionaryOfVariableBindings(username) method:@"POST"];
    
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
			user.fullName = userDict[@"full_name"];
            user.totalKM = [userDict[@"totalDistance"] doubleValue];
            user.obdDistance = [userDict[@"obdDistance"] respondsToSelector:@selector(doubleValue)] ? [userDict[@"obdDistance"] doubleValue] : 0;
            user.rank = [userDict[@"overallRank"] integerValue];
            user.weekRank = [userDict[@"weeklyRank"] integerValue];
            user.totalTracks = [userDict[@"totalTracks"] integerValue];
            user.totalPhotos = [userDict[@"totalPhotos"] integerValue];
            
            if (userDict[@"gamification"]) {
                NSDictionary *gamification = userDict[@"gamification"];
                user.gameInfo = [OSVGamificationInfo new];
                user.gameInfo.totalPoints = [gamification[@"total_user_points"] integerValue];
                user.gameInfo.totalLevelPoints = [gamification[@"level_target"] integerValue];
                user.gameInfo.levelPoints = [gamification[@"level_progress"] integerValue];
                user.gameInfo.rank = [gamification[@"rank"] integerValue];
                user.gameInfo.level = [gamification[@"level"] integerValue];
                user.gameInfo.levelName = gamification[@"levelName"];
                if ([gamification[@"region"] isKindOfClass:[NSDictionary class]]) {
                    user.gameInfo.regionCode = gamification[@"region"][@"country_code"];
                    user.gameInfo.regionRank = [gamification[@"region"][@"rank"] integerValue];
                    user.gameInfo.regionTotalPoints = [gamification[@"region"][@"points"] integerValue];
                }
            }
            
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
                user.userID = userDict[@"id"];
                user.name = userDict[@"username"];
                user.totalKM = [userDict[@"total_km"] doubleValue];
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

- (void)gameLeaderBoardForCountry:(NSString *)countryCode
                         fromDate:(NSDate *)date
                   withCompletion:(void (^)(NSArray *leaderBoard, NSError *error))completion {
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [self.configurator osvBaseURL], kgameLeaderBoard]];
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    if (countryCode) {
        dictionary[@"countryCode"] = countryCode;
    }
    
    if (date) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd"];
        dictionary[@"fromDate"] = [formatter stringFromDate:date];
    }
    
    AFHTTPRequestOperation *requestOperation = [OSVAPIUtils requestWithURL:url
                                                                parameters:dictionary
                                                                    method:@"POST"];
    
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (!operation.isCancelled) {
            if (!responseObject) {
                completion(nil, [NSError errorWithDomain:@"OSVAPI" code:1 userInfo:@{@"Response":@"NoResponse"}]);
                return;
            }
            
            NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:nil];
            NSArray *osvUsersArray = response[@"osv"][@"users"];
            
            NSMutableArray *usersArray = [NSMutableArray array];
            int rank = 0;
            for (NSDictionary *userDict in osvUsersArray) {
                rank += 1;
                OSVUser *user = [OSVUser new];
                user.userID = userDict[@"id"];
                user.name = userDict[@"username"];
                user.rank = rank;
                user.gameInfo = [OSVGamificationInfo new];
                user.gameInfo.totalPoints = [userDict[@"total_user_points"] doubleValue];
                user.gameInfo.regionCode = userDict[@"country_code"];
                
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
