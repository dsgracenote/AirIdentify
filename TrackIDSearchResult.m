//
//  TrackIDSearchResult.m
//  AirIdentifyServer
//
//  Created by Kshitij Deshpande on 8/1/13.
//  Copyright (c) 2013 Gracenote. All rights reserved.
//

#import "TrackIDSearchResult.h"
#import "AppDelegate.h"

@implementation TrackIDSearchResult


- (void) GNResultReady:(GNSearchResult*)result
{
    AppDelegate *delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    [delegate trackidSearchResultReceived:result];
}

@end
