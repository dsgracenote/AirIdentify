//
//  GUIDelegate.h
//  AirIdentifyClient
//
//  Created by Kshitij Deshpande on 7/31/13.
//  Copyright (c) 2013 Gracenote. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GUIDelegate <NSObject>

@required

-(void) displayCurrentlyPlayingTrackWithData:(NSData*) data;

@end
