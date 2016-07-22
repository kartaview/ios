//
//  OSVSequence+Convertor.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 18/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import "OSVServerSequence.h"
#import "OSVSequence.h"

@interface OSVServerSequence (Convertor)

+ (OSVServerSequence *)trackFromDictionary:(NSDictionary *)seqDictionary;
+ (OSVServerSequence *)sequenceFromDictionary:(NSDictionary *)seqDictionary;
+ (OSVServerSequence *)sequenceFromSequence:(OSVSequence *)seq;
+ (OSVServerSequencePart *)sequenceFormDictionaryPart:(NSDictionary *)seqdict;


@end
