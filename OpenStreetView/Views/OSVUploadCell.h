//
//  OSVUploadCell.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 09/11/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OSVUploadCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;
@property (weak, nonatomic) IBOutlet UILabel        *progressLabel;

@end
