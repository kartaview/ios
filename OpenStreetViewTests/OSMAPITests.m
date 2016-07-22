//
//  OSMAPITests.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 29/10/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OSMAPI.h"

@interface OSMAPITests : XCTestCase 

@property (nonatomic, strong) XCTestExpectation *loginExpectations;
@property (nonatomic, strong) XCTestExpectation *logoutExpectations;

@end

@implementation OSMAPITests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)test01Login {
    OSMAPI *api = [OSMAPI sharedInstance];
    self.loginExpectations = [self expectationWithDescription:@"High Expectations"];
    [api logIn];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)test02Logout {
    OSMAPI *api = [OSMAPI sharedInstance];
    [api logout];
    XCTAssertFalse(api.isAuthorized, @"User should be logout");
}

//- (void)test02SignUp {
//    OSMAPI *api = [OSMAPI new];
//    [api signUp];
//    XCTAssertFalse(api.isAuthorized, @"User should be logout");
//}

- (void)osmAPI:(OSMAPI *)osmAPI didFinishLogInWithUser:(OSMUser *)user {
    XCTAssert(osmAPI.isAuthorized, @"When login is finished the api should return isAuthorized = true");
    XCTAssert([osmAPI osmUser]&&[osmAPI osmUser].userID &&[osmAPI osmUser].name && ![[osmAPI osmUser].name isEqualToString:@""], @"OSM Login Made user should be available");
    [self.loginExpectations fulfill];
}

- (void)osmAPI:(OSMAPI *)osmAPI didFailLogInWithError:(NSError *)error {
    XCTFail(@"This metod shouldent be called");
    [self.loginExpectations fulfill];
}

@end
