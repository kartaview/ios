//
//  OSVCamViewController.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 09/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import "AVCamViewController.h"

@class SKMapView;

@interface OSVCamViewController : AVCamViewController

@property (weak, nonatomic) IBOutlet UILabel            *sugestionLabel;
@property (weak, nonatomic) IBOutlet UIImageView        *arrowImage;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topSugestion;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *centerSugestion;


- (void)updateUIInfo;

@end
