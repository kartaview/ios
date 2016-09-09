//
//  OSVPhotoSyncController.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 10/02/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVPhotoSyncController.h"
#import "OSVPersistentManager.h"
#import "OSVSyncUtils.h"
#import "OSVAPI.h"

#import <SDWebImage/UIImageView+WebCache.h>
@import ImageIO;

@interface OSVPhotoSyncController ()

@property (nonatomic, strong) OSVAPI                        *osvAPI;

@end

@implementation OSVPhotoSyncController

- (void)savePhoto:(OSVPhoto *)photo withImageData:(NSData *)data {
    dispatch_async(dispatch_get_main_queue(), ^{
        [OSVPersistentManager storePhoto:photo];
    });
}

#pragma mark - load image data method

- (void)loadImageDataForPhoto:(id<OSVPhoto>)photo intoImageView:(UIImageView *)imageView withCompletion:(void (^)(id<OSVPhoto>photo, NSError *error))completion {
    
    if ([photo isKindOfClass:[OSVServerPhoto class]]) {
        NSURL *imageURL = [self.osvAPI imageURLForPhoto:photo];
        SDWebImageManager *manager = [SDWebImageManager sharedManager];
        [manager downloadImageWithURL:imageURL options:SDWebImageLowPriority progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            if (!image) {
                photo.image = photo.thumbnail;
            } else {
                photo.image = image;
            }
            
            if (photo.image) {
                imageView.image = photo.image;
            }
            completion(photo, nil);
        }];
    } else {

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSString *photoPath = [self.basePathToPhotos stringByAppendingPathComponent:[NSString stringWithFormat:@"/%ld/%@", (long)((OSVPhoto *)photo).localSequenceId, photo.imageName]];
            
            @autoreleasepool {
                NSData *imageData = [NSData dataWithContentsOfFile:photoPath];
                UIImage *localImage = [UIImage imageWithData:imageData];
                photo.image = localImage;
                photo.imageData = imageData;
            
                dispatch_async(dispatch_get_main_queue(), ^{
                    imageView.image = localImage;
                });
                completion(photo, nil);
            }
        });
    }
} 

- (void)loadThumbnailForPhoto:(id<OSVPhoto>)photo intoImageView:(UIImageView *)imageView withCompletion:(void (^)(id<OSVPhoto>photo, NSError *error))completion {
    if ([photo isKindOfClass:[OSVServerPhoto class]]) {
        NSURL *imageURL = [self.osvAPI thumbnailURLForPhoto:photo];
        [imageView sd_setImageWithURL:imageURL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            photo.thumbnail = image;
            imageView.image = image;
            completion(photo, error);
        }];
    } else {
        completion(photo, nil);
    }
}

- (void)loadPreviewForTrack:(id<OSVSequence>)track intoImageView:(UIImageView *)imageView withCompletion:(void (^)(UIImage *image, NSError *error))completion {
    if ([track isKindOfClass:[OSVServerSequence class]]||[track isKindOfClass:[OSVServerSequencePart class]]) {
        NSURL *imageURL = [self.osvAPI previewURLForTrack:track];
        [imageView sd_setImageWithURL:imageURL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            completion(image, error);
        }];
    }
}


- (void)deletePhoto:(id<OSVPhoto>)photo withCompletionBlock:(void (^)(NSError *error))completionBlock  {
    if ([photo isKindOfClass:[OSVServerPhoto class]]) {
        [self.osvAPI deletePhoto:photo forUser:self.user withCompletionBlock:completionBlock];
    } else {
        [OSVPersistentManager removePhoto:photo];
        completionBlock(nil);
    }
}


@end
