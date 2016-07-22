//
//  OSVGalleryCell.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 03/12/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OSVGalleryCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView    *imageView;
@property (weak, nonatomic) IBOutlet UIView         *transparentOverlay;

@property (assign, nonatomic) BOOL  isInEditMode;

@end
