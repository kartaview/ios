//
//  OSVPolyline.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 19/02/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <SKMaps/SKMaps.h>

@interface OSVPolyline : SKPolyline

@property (nonatomic, assign) BOOL          isLocal;
@property (nonatomic, assign) NSInteger     coverage;

@end
