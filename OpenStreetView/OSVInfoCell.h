//
//  OSVInfoCell.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 06/07/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OSVInfoCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *imagesInfo;
@property (weak, nonatomic) IBOutlet UILabel *tracksInfo;
@property (weak, nonatomic) IBOutlet UILabel *OBDInfo;
@property (weak, nonatomic) IBOutlet UILabel *distanceInfo;

@end
