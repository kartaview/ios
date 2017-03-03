//
//  OSVLoginController.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 23/06/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>


@class OSVAPI;
@protocol OSVUser;

@interface OSVLoginController : NSObject

@property (nonatomic, readonly, nullable) id<OSVUser>     oscUser;

- (instancetype _Nonnull)initWithOSVAPI:(OSVAPI *_Nonnull)api;

- (void)loginWithPartial:(void (^_Nonnull)(NSError *_Nullable error))partial andCompletion:(void (^ _Nonnull)(NSError * _Nullable error))completion;
- (void)logout;

- (BOOL)userIsLoggedIn;

- (void)rankingWithCompletion:(void (^ _Nonnull)(NSInteger rank, NSError * _Nullable error))completion;
- (void)leaderBoardWithCompletion:(void(^ _Nonnull)(NSArray * _Nullable leaderBoard, NSError * _Nullable error))completion;
- (void)gameLeaderBoardForRegion:(NSString * _Nullable)countryCode
                        formDate:(NSDate * _Nullable)date
                  withCompletion:(void (^_Nonnull)(NSArray *_Nullable, NSError * _Nullable))completion;

- (void)osvUserInfoWithCompletion:(void (^_Nonnull)(id<OSVUser> _Nullable user, NSError *_Nullable error))completion;

- (NSURL *_Nullable)getAppLink;
- (void)checkForAppUpdateWithCompletion:(void (^_Nonnull)(BOOL response))completion;

@end
