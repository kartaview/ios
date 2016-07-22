//
//  OSVMyTracksCell.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 06/07/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVMyTracksCell.h"

@interface OSVMyTracksCell ()

@property (weak, nonatomic) IBOutlet UILabel *title;

@end

@implementation OSVMyTracksCell

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.title.text = NSLocalizedString(@"My uploaded tracks", @"");
    }
    
    return self;
}


@end
