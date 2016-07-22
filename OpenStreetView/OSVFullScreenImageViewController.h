//
//  OSVFullScreenImageViewController.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 22/11/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OSVPhoto.h"

@protocol OSVFullScreenImageViewControllerDelegate;

@interface OSVFullScreenImageViewController : UIViewController

@property (strong, nonatomic) NSArray<id <OSVPhoto>>    *datasource;
@property (strong, nonatomic) id<OSVPhoto>              selectedPhoto;
@property (nonatomic, strong) NSIndexPath               *selectedIndexPath;
@property (nonatomic, strong) UIImageView               *imageView;

@property (weak, nonatomic) id<OSVFullScreenImageViewControllerDelegate> delegate;

@end


@protocol OSVFullScreenImageViewControllerDelegate <NSObject>

@optional

- (void)willDissmissViewController:(OSVFullScreenImageViewController *)vc;
- (void)didDissmissViewController:(OSVFullScreenImageViewController *)vc;

@end