//
//  OSVSettingsDetails.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 12/07/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OSVSectionItem;

@interface OSVSettingsDetails : UIViewController

@property (weak, nonatomic) IBOutlet UIButton   *titleButton;
@property (nonatomic, strong) OSVSectionItem    *item;

- (void)reloadData;

@end
