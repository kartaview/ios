//
//  OSMParser.h
//  XMLParser
//
//  Created by Cristian Chertes on 10/02/15.
//  Copyright (c) 2015 Cristian Chertes. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OSMUser;

typedef void (^CompletionHandler)(OSMUser *user);

@interface OSMParser : NSObject

@property (nonatomic, strong) CompletionHandler completionHandler;

- (void)parseWithData:(NSData *)data andCompletionHandler:(void (^)(OSMUser *user))completionHandler;

@end
