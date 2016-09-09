//
//  OSVFullScreenImageCell.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 08/03/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVFullScreenImageCell.h"

@interface OSVFullScreenImageCell () <UIScrollViewDelegate>

@property (nonatomic) CGFloat lastScale;

@end

@implementation OSVFullScreenImageCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

- (void)awakeFromNib{
    [super awakeFromNib];
    self.scrollView.minimumZoomScale=1;
    self.scrollView.maximumZoomScale=6.0;
    
    self.scrollView.delegate = self;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.image;
}

- (void)prepareForReuse {
    [self.scrollView setZoomScale:1.0f];
    self.image.image = nil;
}

@end
