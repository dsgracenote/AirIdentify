//
//  TrackInfo.h
//  AirIdentifyServer
//
//  Created by Kshitij Deshpande on 8/1/13.
//  Copyright (c) 2013 Gracenote. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class TrackHistory;

@interface TrackInfo : NSManagedObject

@property (nonatomic, retain) NSString * trackTitle;
@property (nonatomic, retain) NSString * artistName;
@property (nonatomic, retain) NSString * trackID;
@property (nonatomic, retain) NSString * albumName;
@property (nonatomic, retain) NSSet *trackhistory;
@property (nonatomic, retain) NSDate* infoAddedDate;

@end

@interface TrackInfo (CoreDataGeneratedAccessors)

- (void)addTrackhistoryObject:(TrackHistory *)value;
- (void)removeTrackhistoryObject:(TrackHistory *)value;
- (void)addTrackhistory:(NSSet *)values;
- (void)removeTrackhistory:(NSSet *)values;

@end
