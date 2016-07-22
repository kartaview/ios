//
//  OSVAPI.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 18/09/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//


#import "OSVAPI.h"
#import "OSVUser.h"
#import <UIKit/UIKit.h>
#import "OSVAPIConfigurator.h"
#import "OSVAPISpeedometer.h"
#import "AppDelegate.h"

@interface OSVAPI () <NSURLSessionTaskDelegate>

@property (nonatomic, strong) NSOperationQueue      *requestsQueue;
@property (nonatomic, strong) NSOperationQueue      *serialQueue;
@property (nonatomic, strong) OSVAPIConfigurator    *defaultConfigurator;

@property (nonatomic, strong) NSMutableData         *mutableData;

@property (nonatomic, copy) void (^didFinishUpload)(NSInteger photoId, NSError *_Nullable error);

@property (nonatomic, copy, nullable) void (^uploadProgressBlock)(long long totalBytes, long long totalBytesExpected);

@end

@implementation OSVAPI

@synthesize requestsQueue = _requestsQueue;
@synthesize serialQueue = _serialQueue;

- (instancetype)init {
    self = [super init];
    if (self) {
        self.requestsQueue = [[NSOperationQueue alloc] init];
        self.serialQueue = [[NSOperationQueue alloc] init];
        [self.serialQueue setMaxConcurrentOperationCount:1];
        self.defaultConfigurator = [OSVAPIConfigurator new];
        self.configurator = self.defaultConfigurator;
        self.mutableData = [NSMutableData data];
        self.speedometer = [OSVAPISpeedometer new];
    }
    
    return self;
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
//    NSLog(@"uploading stuff");
    
    if (!self.uploadProgressBlock) {
        return;
    }
    self.uploadProgressBlock(totalBytesSent, totalBytesExpectedToSend);
    self.speedometer.bytesInLastSample += bytesSent;
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    if (data) {
        [self.mutableData appendData:data];
    }
}

- (void)URLSession:(__unused NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    [self.speedometer cancelSpeedCalculationTimer];

    if (error.code == NSURLErrorCancelled) {
        return;
    }
    
    if (!self.didFinishUpload) {
        return;
    }
    
    if (error) {
        self.didFinishUpload(-1, error);
        return;
    }
    
    NSError *serializationError;
    NSDictionary *responsedictionary = [NSJSONSerialization JSONObjectWithData:self.mutableData options:NSJSONReadingAllowFragments error:&serializationError];

    if (!self.mutableData || !responsedictionary) {
        self.didFinishUpload(-1, [NSError errorWithDomain:@"OSVAPI" code:1 userInfo:@{@"Response":@"NoResponse"}]);
        return;
    }
    
    NSDictionary *osvDictionary = responsedictionary[@"osv"];
    NSDictionary *dictionary = osvDictionary[@"photo"];
    
    if (!dictionary) {
        dictionary = osvDictionary[@"sequence"];
    }
    
    if (!dictionary) {
        dictionary = osvDictionary[@"video"];
    }
    
    NSString *uid = dictionary[@"id"];
    NSError *responseError = nil;
    if (!uid) {
        if ([responsedictionary[@"status"][@"apiMessage"] isEqualToString:@" An argument is out of range (sequenceId)"]) {
            responseError = [NSError errorWithDomain:@"OSVAPI" code:612 userInfo:@{@"Response" : responsedictionary[@"status"][@"httpMessage"],
                                                                                   @"Sugestion": responsedictionary[@"status"][@"apiMessage"]}];
        } else if ([responsedictionary[@"status"][@"apiMessage"] isEqualToString:@" You are not allowed to add a duplicate entry (sequenceIndex)"]) {
            responseError = [NSError errorWithDomain:@"OSVAPI" code:613 userInfo:@{@"Response" : responsedictionary[@"status"][@"httpMessage"],
                                                                                   @"Sugestion": responsedictionary[@"status"][@"apiMessage"]}];
        } else {
            responseError = [NSError errorWithDomain:@"OSVAPI" code:1 userInfo:@{@"Response":responsedictionary}];

        }
    }
    self.didFinishUpload([uid integerValue], responseError);
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    if (appDelegate.sessionCompletionHandler) {
        void (^completionHandler)() = appDelegate.sessionCompletionHandler;
        appDelegate.sessionCompletionHandler = nil;
        completionHandler();
    }
//    NSLog(@"Task complete");
}

@end
