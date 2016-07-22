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

@property (nonatomic, strong) OSVAPI            *osvAPI;

@end

@implementation OSVPhotoSyncController

- (void)savePhoto:(OSVPhoto *)photo withImageData:(NSData *)data {
    dispatch_async(dispatch_get_main_queue(), ^{
        [OSVPersistentManager storePhoto:photo];
    });
}

- (void)uploadPhoto:(OSVPhoto *)photo withCompletion:(void (^)(NSError *))completion {
    
    if (![OSVSyncUtils hasInternetPermissions]) {
        completion([NSError errorWithDomain:@"OSVConnectivity" code:1 userInfo:@{@"Request":@"NotAllowed"}]);
        return;
    }
    
    if (![self userIsLoggedIn]) {
        completion([NSError errorWithDomain:@"OSMAPI" code:1 userInfo:@{@"Authentication":@"UserAutenticationRequired"}]);
        return;
    }
    
    [OSVSyncUtils correctImageDataForPhoto:photo];
    [self.osvAPI uploadPhoto:photo withProgressBlock:^(long long totalBytes, long long totalBytesExpected) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kDidReceiveProgress object:nil userInfo:@{@"progress":@(totalBytes),
                                                                                                             @"totalSize":@(totalBytesExpected)}];
        
    } andCompletionBlock:^(NSInteger photoId, NSError * _Nullable error) {
        completion(error);
        
        if (error) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kDidFinishUploadingPhoto object:nil userInfo:@{@"error": error}];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:kDidFinishUploadingPhoto object:nil userInfo:@{}];
        }
    }];
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
        if (photo.thumbnail) {
            imageView.image = photo.thumbnail;
            completion(photo, nil);
            return;
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSString *photoPath = [self.basePathToPhotos stringByAppendingPathComponent:[NSString stringWithFormat:@"/%ld/%@", (long)((OSVPhoto *)photo).localSequenceId, photo.imageName]];
            @autoreleasepool {
                NSData *imageData = [NSData dataWithContentsOfFile:photoPath];
                if (!imageData) {
                    completion(nil, [NSError new]);
                    return;
                }
                
                CGImageRef imageref = createThumbnailImageFromData(imageData, 210);
                UIImage *someImage = [UIImage imageWithCGImage:imageref];
                photo.thumbnail  = someImage;
                imageData = nil;
                CFRelease(imageref);
                dispatch_async(dispatch_get_main_queue(), ^{
                    imageView.image = someImage;
                });
                completion(photo, nil);
            }
        });
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

CGImageRef createCGImageFromFile(NSString *path) {
    // Get the URL for the pathname passed to the function.
    NSURL *url = [NSURL fileURLWithPath:path];
    CGImageRef        myImage = NULL;
    CGImageSourceRef  myImageSource;
    CFDictionaryRef   myOptions = NULL;
    CFStringRef       myKeys[2];
    CFTypeRef         myValues[2];
    
    // Set up options if you want them. The options here are for
    // caching the image in a decoded form and for using floating-point
    // values if the image format supports them.
    myKeys[0] = kCGImageSourceShouldCache;
    myValues[0] = (CFTypeRef)kCFBooleanTrue;
    myKeys[1] = kCGImageSourceShouldAllowFloat;
    myValues[1] = (CFTypeRef)kCFBooleanTrue;
    // Create the dictionary
    myOptions = CFDictionaryCreate(NULL, (const void **) myKeys,
                                   (const void **) myValues, 2,
                                   &kCFTypeDictionaryKeyCallBacks,
                                   & kCFTypeDictionaryValueCallBacks);
    // Create an image source from the URL.
    myImageSource = CGImageSourceCreateWithURL((CFURLRef)url, myOptions);
    CFRelease(myOptions);
    // Make sure the image source exists before continuing
    if (myImageSource == NULL){
        fprintf(stderr, "Image source is NULL.");
        return  NULL;
    }
    // Create an image from the first item in the image source.
    myImage = CGImageSourceCreateImageAtIndex(myImageSource,
                                              0,
                                              NULL);
    
    CFRelease(myImageSource);
    // Make sure the image exists before continuing
    if (myImage == NULL){
        fprintf(stderr, "Image not created from image source.");
        return NULL;
    }
    
    return myImage;
}

CGImageRef createThumbnailImageFromData(NSData *data, int imageSize) {
    CGImageRef        myThumbnailImage = NULL;
    CGImageSourceRef  myImageSource;
    CFDictionaryRef   myOptions = NULL;
    CFStringRef       myKeys[3];
    CFTypeRef         myValues[3];
    CFNumberRef       thumbnailSize;
    
    // Create an image source from NSData; no options.
    myImageSource = CGImageSourceCreateWithData((CFDataRef)data,
                                                NULL);
    // Make sure the image source exists before continuing.
    if (myImageSource == NULL){
        fprintf(stderr, "Image source is NULL.");
        return  NULL;
    }
    
    // Package the integer as a  CFNumber object. Using CFTypes allows you
    // to more easily create the options dictionary later.
    thumbnailSize = CFNumberCreate(NULL, kCFNumberIntType, &imageSize);
    
    // Set up the thumbnail options.
    myKeys[0] = kCGImageSourceCreateThumbnailWithTransform;
    myValues[0] = (CFTypeRef)kCFBooleanTrue;
    myKeys[1] = kCGImageSourceCreateThumbnailFromImageIfAbsent;
    myValues[1] = (CFTypeRef)kCFBooleanTrue;
    myKeys[2] = kCGImageSourceThumbnailMaxPixelSize;
    myValues[2] = (CFTypeRef)thumbnailSize;
    
    myOptions = CFDictionaryCreate(NULL, (const void **) myKeys,
                                   (const void **) myValues, 3,
                                   &kCFTypeDictionaryKeyCallBacks,
                                   & kCFTypeDictionaryValueCallBacks);
    
    // Create the thumbnail image using the specified options.
    myThumbnailImage = CGImageSourceCreateThumbnailAtIndex(myImageSource,
                                                           0,
                                                           myOptions);
    // Release the options dictionary and the image source
    // when you no longer need them.
    CFRelease(thumbnailSize);
    CFRelease(myOptions);
    CFRelease(myImageSource);
    
    // Make sure the thumbnail image exists before continuing.
    if (myThumbnailImage == NULL){
        fprintf(stderr, "Thumbnail image not created from image source.");
        return NULL;
    }
    
    return myThumbnailImage;
}


@end
