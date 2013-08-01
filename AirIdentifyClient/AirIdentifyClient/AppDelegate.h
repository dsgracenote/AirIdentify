//
//  AppDelegate.h
//  AirIdentifyClient
//
//  Created by Kshitij Deshpande on 7/30/13.
//  Copyright (c) 2013 Gracenote. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreBluetooth/CoreBluetooth.h"
#import "AVFoundation/AvFoundation.h"
#import "CoreLocation/CoreLocation.h"
#import "MediaPlayer/MediaPlayer.h"
#import "MultipeerConnectivity/MCSession.h"
#import "MultipeerConnectivity/MCPeerID.h"
#import "MultipeerConnectivity/MCNearbyServiceBrowser.h"

#import <GracenoteMusicID/GNAudioConfig.h>
#import <GracenoteMusicID/GNAudioSourceMic.h>
#import <GracenoteMusicID/GNConfig.h>
#import <GracenoteMusicID/GNRecognizeStream.h>
#import <GracenoteMusicID/GNSearchResultReady.h>
#import <GracenoteMusicID/GNSearchResult.h>
#import <GracenoteMusicID/GNOperations.h>

#import "GUIDelegate.h"


typedef enum
{
    CARDIO_BEACON_TYPE = 700,
    WEIGHTS_BEACON_TYPE,
    TRAINING_BEACON_TYPE,
    YOGA_BEACON_TYPE,
    CROSSTRAINING_BEACON_TYPE,
    CYCLING_BEACON_TYPE
    
}MAJORBEACONTYPES;

typedef enum
{
    SITTING_BEACON_TYPE = 7000,
    WALKING_BEACON_TYPE,
    RUNNING_BEACON_TYPE,
    
}MINORBEACONTYPES;


@interface AppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate, GNSearchResultReady, MCSessionDelegate, MCNearbyServiceBrowserDelegate, GNAudioSourceDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) CLLocationManager *locationManager;

@property (weak, nonatomic) MPMusicPlayerController *musicPlayerController;

@property (weak) id<GUIDelegate> guidelegate;


-(void)fileSearchResultReceived:(GNSearchResult*) fileSearchResult;
-(void)fingerprintSearchResultReceived:(GNSearchResult*) fingerprintSearchResult;

@end
