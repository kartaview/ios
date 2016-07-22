//
//  OSVAPIConfigurator.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 07/01/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OSVAPIConfigurator <NSObject>

- (nonnull NSString *)osvBaseURL;
- (nonnull NSString *)osvAPIVerion;

@end

@interface OSVAPIConfigurator : NSObject <OSVAPIConfigurator>

@end
