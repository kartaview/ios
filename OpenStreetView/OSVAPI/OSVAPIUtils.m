//
//  OSVAPIUtils.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 23/11/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import "OSVAPIUtils.h"

@implementation OSVAPIUtils

+ (NSData *)multipartFormDataQueryStringFromParameters:(NSDictionary *)parameters withEncoding:(NSStringEncoding)encoding boundary:(NSString *)boundary parametersInfo:(NSDictionary *)details {
    NSMutableData *requestData = [NSMutableData data];
    NSData *delimiterLineData = [[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:encoding];
    
    [requestData appendData:delimiterLineData];
    for (NSString *key in parameters.allKeys) {
        
        id value = parameters[key];
        
        NSDictionary *info = details[key];
        
        if ([info isKindOfClass:[NSDictionary class]] && info[@"contentType"] && info[@"format"]) {
        
            NSString *contentType = info[@"contentType"];
            NSString *format = info[@"format"];
            
            [requestData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@.%@\"\r\n", key, key, format] dataUsingEncoding:encoding]];
            [requestData appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n",contentType] dataUsingEncoding:encoding]];
            [requestData appendData:value];
            [requestData appendData:delimiterLineData];
            
        } else {
            [requestData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n%@", key, value] dataUsingEncoding:encoding]];
            [requestData appendData:delimiterLineData];
        }
    }
    
    return requestData;
}

+ (NSString *)generateRandomBoundaryString {
    CFUUIDRef UUID = CFUUIDCreate(kCFAllocatorDefault);
    NSString *randomBoundaryString = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, UUID);
    CFRelease(UUID);
    
    return randomBoundaryString;
}

+ (AFHTTPRequestOperation *)requestWithURL:(NSURL * __nonnull)url parameters:(NSDictionary * __nonnull)dictionary method:(NSString * __nonnull)method {
    NSMutableURLRequest *urlrequest = [[NSMutableURLRequest alloc] initWithURL:url];
    
    NSStringEncoding stringEncoding = NSUTF8StringEncoding;
    NSString *boundaryString = [OSVAPIUtils generateRandomBoundaryString];
    NSString *value = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundaryString];
    [urlrequest setValue:value forHTTPHeaderField:@"Content-Type"];
    @autoreleasepool {
        [urlrequest setHTTPBody:[OSVAPIUtils multipartFormDataQueryStringFromParameters:dictionary withEncoding:stringEncoding boundary:boundaryString parametersInfo:nil]];
    }
    [urlrequest setHTTPMethod:method];
    
    boundaryString = nil;
    
    return [[AFHTTPRequestOperation alloc] initWithRequest:urlrequest];
}

+ (AFHTTPRequestOperation *)requestWithURL:(NSURL *__nonnull)url parameters:(NSDictionary * __nonnull)dictionary parametersInfo:(NSDictionary *__nullable)paramsInfo method:(NSString *__nonnull)method {
    NSMutableURLRequest *urlrequest = [[NSMutableURLRequest alloc] initWithURL:url];
    
    NSStringEncoding stringEncoding = NSUTF8StringEncoding;
    NSString *boundaryString = [OSVAPIUtils generateRandomBoundaryString];
    NSString *value = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundaryString];
    [urlrequest setValue:value forHTTPHeaderField:@"Content-Type"];
    @autoreleasepool {
        [urlrequest setHTTPBody:[OSVAPIUtils multipartFormDataQueryStringFromParameters:dictionary withEncoding:stringEncoding boundary:boundaryString parametersInfo:paramsInfo]];
    }
    [urlrequest setHTTPMethod:method];
    
    boundaryString = nil;
    
    return [[AFHTTPRequestOperation alloc] initWithRequest:urlrequest];
}

+ (NSString *)deviceUUID {
    if([[NSUserDefaults standardUserDefaults] objectForKey:[[NSBundle mainBundle] bundleIdentifier]]) {
        return [[NSUserDefaults standardUserDefaults] objectForKey:[[NSBundle mainBundle] bundleIdentifier]];
    }
    
    @autoreleasepool {
        
        CFUUIDRef uuidReference = CFUUIDCreate(nil);
        CFStringRef stringReference = CFUUIDCreateString(nil, uuidReference);
        NSString *uuidString = (__bridge NSString *)(stringReference);
        [[NSUserDefaults standardUserDefaults] setObject:uuidString forKey:[[NSBundle mainBundle] bundleIdentifier]];
        [[NSUserDefaults standardUserDefaults] synchronize];
        CFRelease(uuidReference);
        CFRelease(stringReference);
        return uuidString;
    }
}

@end
