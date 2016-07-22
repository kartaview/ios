//
//  OSMPhoto.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 15/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "OSVPhotoData.h"


@protocol OSVPhoto <NSObject>

/** The image path where the imagedata is stored.
 */
@property (nonatomic, strong) NSString              *imageName;

@property (nonatomic, strong) OSVPhotoData          *photoData;

/** The image data stored on disk/server for each photo.
 */
@property (nonatomic, strong) UIImage               *image;
@property (nonatomic, strong) UIImage               *thumbnail;
/** The image data stored on disk/server for each photo.
 */
@property (nonatomic, strong) NSData                *imageData;

@property (nonatomic, assign) NSInteger             serverSequenceId;
@property (nonatomic, assign) UIImageOrientation    correctionOrientation;

@property (nonatomic, assign) BOOL                  hasOBD;

@end


@interface OSVPhoto : NSObject <OSVPhoto>

@property (nonatomic, assign) NSInteger              localSequenceId;

@end



