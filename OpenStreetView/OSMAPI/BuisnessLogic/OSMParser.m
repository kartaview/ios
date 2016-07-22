//
//  OSMParser.m
//  XMLParser
//
//  Created by Cristian Chertes on 10/02/15.
//  Copyright (c) 2015 Cristian Chertes. All rights reserved.
//

#import "OSMParser.h"
#import "OSMUser.h"

@interface OSMParser () <NSXMLParserDelegate>

@property (nonatomic, strong) NSXMLParser       *xmlParser;
@property (nonatomic, strong) NSMutableArray    *objects;
@property (nonatomic, strong) OSMUser           *user;

@end

@implementation OSMParser

#pragma mark - Public methods

- (void)parseWithData:(NSData *)data andCompletionHandler:(void (^)(OSMUser *user))completionHandler {
    self.completionHandler = completionHandler;
    self.xmlParser = [[NSXMLParser alloc] initWithData:data];
    self.xmlParser.delegate = self;
    
    [self.xmlParser parse];
}

#pragma mark - Private methods

- (NSDate *)dateFromString:(NSString *)string {
    if (string) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
        string = [string stringByReplacingOccurrencesOfString:@"T" withString:@" "];
        string = [string stringByReplacingOccurrencesOfString:@"Z" withString:@""];
        
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSDate *date = [formatter dateFromString:string];

        return date;
    }
    
    return nil;
}

#pragma mark - NSXMLParserDelegate methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    if (!self.user) {
        self.user = [[OSMUser alloc] init];
    }
    
    if ([elementName isEqualToString:@"user"]) {
        self.user.userID = [[attributeDict valueForKey:@"id"] integerValue];
        self.user.name = [attributeDict valueForKey:@"display_name"];
        NSString *date = [attributeDict valueForKey:@"account_created"];
        self.user.creationDate = [self dateFromString:date];
        
    }
    
    if ([elementName isEqualToString:@"img"]) {
        self.user.profilePictureURL = [attributeDict valueForKey:@"href"];
    }
    
    if ([elementName isEqualToString:@"changesets"]) {
        self.user.changesetsCount = [[attributeDict valueForKey:@"count"]integerValue];
    }
    
    if ([elementName isEqualToString:@"traces"]) {
        self.user.tracesCount = [[attributeDict valueForKey:@"count"]integerValue];
    }
    
    if ([elementName isEqualToString:@"home"]) {
        float lat = [[attributeDict valueForKey:@"lat"] floatValue];
        float lon = [[attributeDict valueForKey:@"lon"] floatValue];
        self.user.homeCoordinate = CLLocationCoordinate2DMake(lat, lon);
    }
    
    if ([elementName isEqualToString:@"description"]) {
        self.user.descriptions = [attributeDict valueForKey:@"description"];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    if ([elementName isEqualToString:@"osm"]) {
        self.completionHandler(self.user);
        self.user = nil;
    }
}

@end
