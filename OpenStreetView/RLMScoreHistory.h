//
//  RLMScoreHistory.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 21/11/2016.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <Realm/Realm.h>

@interface RLMScoreHistory : RLMObject

@property (nonatomic, strong) NSString  *scoreHistoryID;

@property (nonatomic, assign) NSInteger localSequenceID;

@property (nonatomic, assign) NSInteger coverage;
@property (nonatomic, assign) NSInteger photos;
@property (nonatomic, assign) NSInteger photosWithOBD;
@property (nonatomic, assign) NSInteger detectedSigns;

@end
