//
//  OSVAPIUtils.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 23/11/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPRequestOperation.h"

#define safeString(obj) (obj != nil ? obj : @"")

@interface OSVAPIUtils : NSObject
//+ (NSData * _Nonnull)multipartFormDataQueryStringFromParameters:(NSDictionary * _Nonnull)parameters withEncoding:(NSStringEncoding)encoding boundary:(NSString * _Nonnull)boundary;
+ (NSData * _Nonnull)multipartFormDataQueryStringFromParameters:(NSDictionary * _Nonnull)parameters withEncoding:(NSStringEncoding)encoding boundary:(NSString * _Nonnull)boundary parametersInfo:(NSDictionary * _Nullable)details;

+ (NSString * _Nonnull)generateRandomBoundaryString;
+ (AFHTTPRequestOperation * _Nonnull)requestWithURL:(NSURL * __nonnull)url parameters:(NSDictionary * __nonnull)dictionary method:(NSString * __nonnull)method;
+ (NSString * _Nonnull)deviceUUID;

@end
