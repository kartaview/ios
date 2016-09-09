//
//  OSVTrackCell.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 06/07/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVTrackCell.h"
#import "UIColor+OSVColor.h"

@interface OSVTrackCell ()
@property (weak, nonatomic) IBOutlet UIView *backgroundPaternView;

@end

@implementation OSVTrackCell

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    
    if (self) {

    }
    
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.backgroundPaternView.layer.borderColor = [UIColor colorWithHex:0x31333b].CGColor;
    self.backgroundPaternView.layer.borderWidth = 1;
    self.backgroundPaternView.layer.cornerRadius = 2;
    self.backgroundPaternView.clipsToBounds = YES;
}

- (void)prepareForReuse {
    [super prepareForReuse];
   
    self.locationLabel.text = @"-";
    self.photoCountLabel.text = @"-";
    self.distanceLabel.text = @"-";
    self.dateLabel.text = @"-";
}

@end
