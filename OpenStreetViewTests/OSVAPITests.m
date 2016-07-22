//
//  OSVAPITests.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 29/10/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OSVAPI.h"
#import "OSVUser.h"
#import "OSMUser.h"

#define kUserName @"Gropita"
#define kUserID 131245

@interface OSVAPITests : XCTestCase

@end

@implementation OSVAPITests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    
    
    
}


- (void)testOSVList {
    id<OSVUser> user = (id<OSVUser>)[OSMUser new];
    user.userID = kUserID;
    user.name = kUserName;
    
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
