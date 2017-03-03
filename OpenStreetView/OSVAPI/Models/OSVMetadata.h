//
//  OSVMetadata.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 28/10/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OSVMetadata : NSObject

@property (nonatomic, assign) NSInteger index;
@property (nonatomic, assign) NSInteger pageIndex;
@property (nonatomic, assign) NSInteger totalItems;
@property (nonatomic, assign) NSInteger itemsPerPage;
@property (nonatomic, assign) BOOL      uploadingMetadata;

+ (OSVMetadata *)metadataError;

- (BOOL)isLastPage;
- (NSInteger)totalPages;

@end
