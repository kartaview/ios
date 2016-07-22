//
//  OSVGalleryViewController.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 21/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OSVGalleryViewController : UIViewController

@property (strong, nonatomic) NSMutableArray        *datasource;
@property (assign, nonatomic) BOOL                  didChanges;
@property (assign, nonatomic) BOOL                  isPresented;

@end
