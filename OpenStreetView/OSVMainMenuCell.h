//
//  OSVMainMenuCell.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 05/07/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OSVMainMenuCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView    *icon;
@property (assign, nonatomic) BOOL                  active;
@property (weak, nonatomic) IBOutlet UILabel        *title;

@end
