//
//  OSVLoadingCell.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 13/10/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OSVLoadingCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView    *activityIndicator;
@property (weak, nonatomic) IBOutlet UILabel                    *title;
@property (weak, nonatomic) IBOutlet UILabel                    *subTitle;

@end
