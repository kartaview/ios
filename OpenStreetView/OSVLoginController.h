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

@property (nonatomic) NSString                  *basePathToPhotos;
@property (nonatomic, readonly) id<OSVUser>     user;

- (instancetype)initWithOSVAPI:(OSVAPI *)api basePath:(NSString *)basePath;

- (void)loginWithCompletion:(void (^)(NSError *error))completion;
- (void)logout;

- (BOOL)userIsLoggedIn;

- (void)rankingWithCompletion:(void (^)(NSInteger rank, NSError *error))completion;
- (void)osvUserInfoWithCompletion:(void (^)(id<OSVUser> user, NSError *error))completion;

- (NSURL *)getAppLink;
- (void)getApiVersionWithCompletion:(void (^)(BOOL response))completion;

@end
