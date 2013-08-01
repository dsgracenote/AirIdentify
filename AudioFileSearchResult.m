//
//  AudioFileSearchResult.m
//  AirIdentifyClient
//
//  Created by Kshitij Deshpande on 7/31/13.
//  Copyright (c) 2013 Gracenote. All rights reserved.
//

#import "AudioFileSearchResult.h"
#import "AppDelegate.h"

@implementation AudioFileSearchResult


- (void) GNResultReady:(GNSearchResult*)result
{
    
    AppDelegate *delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    [delegate fileSearchResultReceived:result];
}

@end
