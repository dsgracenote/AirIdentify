//
//  User.h
//  AirIdentifyServer
//
//  Created by Kshitij Deshpande on 8/1/13.
//  Copyright (c) 2013 Gracenote. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class TrackHistory;

@interface User : NSManagedObject

@property (nonatomic, retain) NSString * userID;
@property (nonatomic, retain) NSString * userName;
@property (nonatomic, retain) NSString * contactInfomation;
@property (nonatomic, retain) NSString * twitter;
@property (nonatomic, retain) TrackHistory *trackhistory;

@end
