//
//  OSVPhotoSyncController.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 10/02/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSVLoginController.h"
#import "OSVPhoto.h"
#import "OSVSequence.h"

#define kDidFinishUploadingAll      @"kDidFinishUploadingAll"
#define kDidFinishUploadingPhoto    @"kDidFinishUploadingPhoto"
#define kDidFinishUploadingSequence @"kDidFinishUploadingSequence"
#define kDidReceiveProgress         @"kDidReceiveProgress"
#define kDidChangedUploadProcess    @"kDidChangedUploadProcess"

@interface OSVPhotoSyncController : OSVLoginController

//Save photo
//localy
- (void)savePhoto:(OSVPhoto *)photo;

//delete photo localy/server
- (void)deletePhoto:(id<OSVPhoto>)photo withCompletionBlock:(void (^)(NSError *error))completionBlock;

//Get image data
- (void)loadImageDataForPhoto:(id<OSVPhoto>)photo intoImageView:(UIImageView *)imageView withCompletion:(void (^)(id<OSVPhoto>photo, NSError *error))completion;
- (void)loadThumbnailForPhoto:(id<OSVPhoto>)photo intoImageView:(UIImageView *)imageView withCompletion:(void (^)(id<OSVPhoto>photo, NSError *error))completion;

- (void)loadPreviewForTrack:(id<OSVSequence>)track intoImageView:(UIImageView *)imageView withCompletion:(void (^)(UIImage *image, NSError *error))completion;

@end
