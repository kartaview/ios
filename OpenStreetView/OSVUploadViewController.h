//
//  OSVUploadViewController.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 15/01/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OSVUploadViewController : UIViewController

@property (strong, nonatomic) id previousBarTintColor;
@property (strong, nonatomic) id previousShadowImage;
@property (strong, nonatomic) id previousBackgroundImage;

- (void)uploadSequences;

@end
