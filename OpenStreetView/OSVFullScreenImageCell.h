//
//  OSVFullScreenImageCell.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 08/03/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OSVFullScreenImageCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIImageView *image;

@end
