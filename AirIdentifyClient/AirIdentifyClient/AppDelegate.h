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
#import <Accounts/Accounts.h>

static NSString* const kUserAgent = @"Mozilla/5.0 (iPhone; CPU iPhone OS 5_0 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9A334 Safari/7534.48.3";

typedef enum
{
    YouTubeVideoQualitySmall    ,
    YouTubeVideoQualityMedium   ,
    YouTubeVideoQualityLarge    ,
} YouTubeVideoQuality;

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

@property (copy, nonatomic) NSString *currentlyPlayingTrackID;

@property (strong, nonatomic)          ACAccountStore *accountStore;
@property (strong, nonatomic)          ACAccount      *twitterAccount;


-(void)fileSearchResultReceived:(GNSearchResult*) fileSearchResult;
-(void)fingerprintSearchResultReceived:(GNSearchResult*) fingerprintSearchResult;
-(void)sendSelectedTrackToConnectedPeers;
-(BOOL)userHasAccessToTwitter;

@end
