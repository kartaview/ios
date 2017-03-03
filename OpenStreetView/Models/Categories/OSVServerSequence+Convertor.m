//
//  OSVSequence+Convertor.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 18/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import "OSVServerSequence+Convertor.h"
#import "OSVScoreHistory.h"

@implementation OSVServerSequence (Convertor)

+ (OSVServerSequence *)trackFromDictionary:(NSDictionary *)seqDictionary {
    OSVServerSequence *sequence = [OSVServerSequence new];
    
    NSMutableArray<CLLocation *> *array = [NSMutableArray array];
    NSArray *track = seqDictionary[@"track"];
    
    if ([track isKindOfClass:[NSArray class]]) {
        for (NSInteger i = 0; i < track.count; i++) {
            if ([track[i] isKindOfClass:[NSArray class]]) {
                NSNumber *lat = track[i][0];
                NSNumber *lng = track[i][1];
                CLLocation *location = [[CLLocation alloc] initWithLatitude:[lat doubleValue] longitude:[lng doubleValue]];
                [array addObject:location];
            }
        }
        sequence.track = array;
    }
    sequence.uid = [seqDictionary[@"sequence_id"] integerValue];
    if (!sequence.uid) {
        sequence.uid = [seqDictionary[@"element_id"] hash];
    }
    
    sequence.coverage = [seqDictionary[@"coverage"] integerValue];
    
    return sequence;
}

+ (OSVServerSequence *)sequenceFromDictionary:(NSDictionary *)seqDictionary {

    OSVServerSequence *sequence = [OSVServerSequence new];
    sequence.uid = [seqDictionary[@"id"] integerValue];
    sequence.countryCode = seqDictionary[@"country_code"];
    NSString *string = seqDictionary[@"date_added"];
    NSDateFormatter *dateFormatter  =   [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd (HH:mm)"];
    NSDate *yourDate = [dateFormatter dateFromString:string];
    sequence.dateAdded = yourDate;
    sequence.location = seqDictionary[@"location"];
    sequence.previewImage = seqDictionary[@"thumb_name"];
    sequence.photoCount = [seqDictionary[@"photo_no"] integerValue];
    if ([seqDictionary[@"upload_history"] isKindOfClass:[NSDictionary class]]) {
        sequence.points = [seqDictionary[@"upload_history"][@"points"][@"total"] integerValue];
        sequence.scoreHistory = [NSMutableArray array];
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        
        for (NSDictionary *coverage in seqDictionary[@"upload_history"][@"coverage"]) {
            
            NSInteger multi = [coverage[@"coverage_points"] integerValue]/[coverage[@"coverage_photos_count"] integerValue];

            if (!dict[@(multi)]) {
                dict[@(multi)] = [OSVScoreHistory new];
            }
            
            OSVScoreHistory *history = dict[@(multi)];
            history.coverage += [coverage[@"coverage_value"] integerValue];
            history.distance += [coverage[@"coverage_distance"] doubleValue];
            history.points += [coverage[@"coverage_points"] integerValue];
            history.photos += [coverage[@"coverage_photos_count"] integerValue];
            history.multiplier = history.points/history.photos;
        }
        
        for (NSNumber *key in dict) {
            [sequence.scoreHistory addObject:dict[key]];
        }
        
    }
    
    if ([seqDictionary[@"distance"] respondsToSelector:@selector(doubleValue)]) {
        sequence.length = [seqDictionary[@"distance"] doubleValue] * 1000;
    }
   
    return sequence;
}

+ (OSVServerSequencePart *)sequenceFormDictionaryPart:(NSDictionary *)seqdict {
    OSVServerSequencePart *sequence = [OSVServerSequencePart new];
    sequence.uid = [seqdict[@"sequence_id"] integerValue];
    sequence.previewImage = seqdict[@"photo"];
    sequence.coordinate = CLLocationCoordinate2DMake([seqdict[@"lat"] doubleValue], [seqdict[@"lng"] doubleValue]);
    sequence.selectedIndex = [seqdict[@"sequence_index"] integerValue];
    sequence.author = seqdict[@"author"];
    sequence.photoCount = [seqdict[@"photo_no"] integerValue];

    NSString *string = seqdict[@"date"];
    NSString *dateString = [string stringByAppendingString:[@" " stringByAppendingString:seqdict[@"hour"]]];
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"MM.dd.yyyy HH:mm a"];
    NSDate *yourDate = [dateFormatter dateFromString:dateString];
    sequence.dateAdded = yourDate;
    
    if ([seqdict[@"distance"] respondsToSelector:@selector(doubleValue)]) {
        sequence.length = [seqdict[@"distance"] doubleValue] * 1000;
    }
    
    if ([seqdict[@"address"] isKindOfClass:[NSString class]] &&
         seqdict[@"address"] != nil &&
        ![seqdict[@"address"] isEqualToString:@""]) {
        sequence.location = seqdict[@"address"] ;
    }
    
    return sequence;
}

+ (OSVServerSequence *)sequenceFromSequence:(OSVSequence *)seq {
    OSVServerSequence *sequence = [OSVServerSequence new];
    sequence.dateAdded = seq.dateAdded;
    sequence.uid = seq.uploadID;
    
    sequence.photos = seq.photos;
    
    return sequence;
}

@end
