//
//  OSVMetadata.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 28/10/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import "OSVMetadata.h"

@implementation OSVMetadata

+ (OSVMetadata *)metadataError {
    OSVMetadata *meta = [OSVMetadata new];
    meta.index = -1;
    meta.pageIndex = -1;
    meta.totalItems = -1;
    meta.itemsPerPage = 10;
    meta.uploadingMetadata = NO;
    
    return meta;
}

- (BOOL)isLastPage {
    NSInteger totalPages = self.totalItems / self.itemsPerPage + (self.totalItems % self.itemsPerPage != 0 ? 1 : 0);

    return self.pageIndex == (totalPages-1);
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%p index:%ld, page:%ld, total:%ld, ipp:%ld", self, (long)self.index, (long)self.pageIndex, (long)self.totalItems, (long)self.itemsPerPage];
}

@end
