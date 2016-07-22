//
//  RLMBoundingBox.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 21/12/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RLMBoundingBox <NSObject>

/** The top left coordinate of the bounding box.
 */
@property(nonatomic, assign) CLLocationCoordinate2D topLeftCoordinate;

/** The bottom right coordinate of the bounding box.
 */
@property(nonatomic, assign) CLLocationCoordinate2D bottomRightCoordinate;

@end
