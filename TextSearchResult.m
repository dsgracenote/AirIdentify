//
//  TextSearchResult.m
//  AirIdentifyClient
//
//  Created by Kshitij Deshpande on 8/2/13.
//  Copyright (c) 2013 Gracenote. All rights reserved.
//

#import "TextSearchResult.h"
#import "AppDelegate.h"

@implementation TextSearchResult

- (void) GNResultReady:(GNSearchResult*)result
{
    AppDelegate *delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    [delegate textSearchResultReceived:result];
}

@end
