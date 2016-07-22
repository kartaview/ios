//
//  OSVSequenceCell.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 21/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OSVSequenceCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *subTitle;
@property (weak, nonatomic) IBOutlet UILabel *size;

@property (assign, nonatomic) BOOL isLastCell;

@end
