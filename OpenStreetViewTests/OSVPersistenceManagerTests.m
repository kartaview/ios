//
//  OSVPersistenceManagerTests.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 29/10/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OSVPersistentManager.h"

#define kNumberOFPhotos 500

@interface OSVPersistenceManagerTests : XCTestCase
@property (nonatomic, strong) NSMutableArray *array;
@end

@implementation OSVPersistenceManagerTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)test01PersistenceManagerFullCoverage {
    self.array = [NSMutableArray array];
    
    for (int i = 0; i < kNumberOFPhotos; i++) {
        OSVPhoto *photo = [OSVPhoto new];
        photo.location = CLLocationCoordinate2DMake(45.01, 45.01);
        photo.heading = 45.01;
        photo.image = [UIImage imageNamed:@"cameraOff"];
        photo.imageName = @"imageName";
        photo.timestamp = [NSDate date];
        
        [self.array addObject:photo];
        
        [OSVPersistentManager storePhoto:photo];
    }
    XCTAssert([OSVPersistentManager hasPhotos], @"No photo was detected - there is a problem here");
    
    [OSVPersistentManager getAllSequencesWithCompletion:^(NSArray *sequences, NSInteger photosCount) {
        XCTAssert(photosCount == kNumberOFPhotos, @"The number of photos that are displayed differ from the number of photos saved");
    }];
    
    XCTAssert(self.array.count == kNumberOFPhotos, @"The number of photos that are displayed differ from the number of photos saved");
    for (OSVPhoto *photo in self.array) {
        [OSVPersistentManager removePhoto:photo];
    }
    
    XCTAssert(![OSVPersistentManager hasPhotos], @"should have no photo");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
