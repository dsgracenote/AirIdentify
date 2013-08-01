//
//  TrackHistory.h
//  AirIdentifyServer
//
//  Created by Kshitij Deshpande on 8/1/13.
//  Copyright (c) 2013 Gracenote. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface TrackHistory : NSManagedObject

@property (nonatomic, retain) NSDate * historyDate;
@property (nonatomic, retain) NSString * device;
@property (nonatomic, retain) NSSet *trackinfo;
@property (nonatomic, retain) NSSet *user;
@end

@interface TrackHistory (CoreDataGeneratedAccessors)

- (void)addTrackinfoObject:(NSManagedObject *)value;
- (void)removeTrackinfoObject:(NSManagedObject *)value;
- (void)addTrackinfo:(NSSet *)values;
- (void)removeTrackinfo:(NSSet *)values;

- (void)addUserObject:(NSManagedObject *)value;
- (void)removeUserObject:(NSManagedObject *)value;
- (void)addUser:(NSSet *)values;
- (void)removeUser:(NSSet *)values;

@end
