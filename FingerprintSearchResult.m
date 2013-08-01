//
//  FingerprintSearchResult.m
//  AirIdentifyClient
//
//  Created by Kshitij Deshpande on 7/31/13.
//  Copyright (c) 2013 Gracenote. All rights reserved.
//

#import "FingerprintSearchResult.h"
#import "AppDelegate.h"

@implementation FingerprintSearchResult


- (void) GNResultReady:(GNSearchResult*)result
{
    AppDelegate *delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    [delegate fingerprintSearchResultReceived:result];
}

@end
