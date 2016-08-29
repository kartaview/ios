//
//  OSVFullScreenImageViewController.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 22/11/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OSVSequence.h"

@protocol OSVFullScreenImageViewControllerDelegate;

@interface OSVFullScreenImageViewController : UIViewController

@property (strong, nonatomic) id<OSVSequence>           sequenceDatasource;
@property (strong, nonatomic) id<OSVPhoto>              selectedPhoto;
@property (strong, nonatomic) NSIndexPath               *selectedIndexPath;
@property (strong, nonatomic) UIImageView               *imageView;

@property (weak, nonatomic) id<OSVFullScreenImageViewControllerDelegate> delegate;

@end


@protocol OSVFullScreenImageViewControllerDelegate <NSObject>

@optional

- (void)willDissmissViewController:(OSVFullScreenImageViewController *)vc;
- (void)didDissmissViewController:(OSVFullScreenImageViewController *)vc;

@end