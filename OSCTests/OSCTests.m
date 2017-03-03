//
//  OSCTests.m
//  OSCTests
//
//  Created by Bogdan Sala on 03/02/2017.
//  Copyright © 2017 Bogdan Sala. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OSVUtils.h"

@interface OSCTests : XCTestCase
@property (strong, nonatomic) NSArray *dataSet;
@end

@implementation OSCTests

- (void)setUp {
    [super setUp];
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"MatcherDataSet" ofType:@"json"];
    NSError *deserializingError;
    NSURL *localFileURL = [NSURL fileURLWithPath:filePath];
    NSData *contentOfLocalFile = [NSData dataWithContentsOfURL:localFileURL];
    self.dataSet = [NSJSONSerialization JSONObjectWithData:contentOfLocalFile
                                                options:NSJSONReadingAllowFragments
                                                  error:&deserializingError];
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    NSLog(@">--- count: %ld ---<",self.dataSet.count);
    for (NSDictionary *dict in self.dataSet) {
        NSArray *aLocation = dict[@"aLocation"];
        NSArray *aStart = dict[@"segmentStartLocation"];
        NSArray *aEnd = dict[@"segmentEndLocation"];
        NSString *aDesc = dict[@"description"];
        NSNumber *aDistance = dict[@"distance"];
        
        CLLocation *location = [[CLLocation alloc] initWithLatitude:[aLocation[0] doubleValue] longitude:[aLocation[1] doubleValue]];
        CLLocation *start = [[CLLocation alloc] initWithLatitude:[aStart[0] doubleValue] longitude:[aStart[1] doubleValue]];
        CLLocation *end = [[CLLocation alloc] initWithLatitude:[aEnd[0] doubleValue] longitude:[aEnd[1] doubleValue]];
        
        double distance;
        [OSVUtils nearestLocationToLocation:location
                     onLineSegmentLocationA:start
                                  locationB:end
                                   distance:&distance];
        XCTAssert(ABS(distance - aDistance.doubleValue) < 1, @"\n %@  %f expected:%f result:%f \n", aDesc, distance - aDistance.doubleValue, aDistance.doubleValue, distance);
        
        NSLog(@"%f",ABS(distance - aDistance.doubleValue));
    }
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        for (NSDictionary *dict in self.dataSet) {
            NSArray *aLocation = dict[@"aLocation"];
            NSArray *aStart = dict[@"segmentStartLocation"];
            NSArray *aEnd = dict[@"segmentEndLocation"];
            
            CLLocation *location = [[CLLocation alloc] initWithLatitude:[aLocation[0] doubleValue] longitude:[aLocation[1] doubleValue]];
            CLLocation *start = [[CLLocation alloc] initWithLatitude:[aStart[0] doubleValue] longitude:[aStart[1] doubleValue]];
            CLLocation *end = [[CLLocation alloc] initWithLatitude:[aEnd[0] doubleValue] longitude:[aEnd[1] doubleValue]];
            double distance;
            [OSVUtils nearestLocationToLocation:location onLineSegmentLocationA:start locationB:end distance:&distance];
        }
    }];
}

@end
