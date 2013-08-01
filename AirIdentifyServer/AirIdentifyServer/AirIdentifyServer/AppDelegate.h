//
//  AppDelegate.h
//  AirIdentifyServer
//
//  Created by Kshitij Deshpande on 7/29/13.
//  Copyright (c) 2013 Gracenote. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <UIKit/UIKit.h>
#import "CoreBluetooth/CoreBluetooth.h"
#import "AVFoundation/AvFoundation.h"
#import "CoreLocation/CoreLocation.h"
#import "MediaPlayer/MediaPlayer.h"
#import "MultipeerConnectivity/MCSession.h"
#import "MultipeerConnectivity/MCPeerID.h"
#import "MultipeerConnectivity/MCNearbyServiceAdvertiser.h"

#import <GracenoteMusicID/GNAudioConfig.h>
#import <GracenoteMusicID/GNConfig.h>
#import <GracenoteMusicID/GNSearchResultReady.h>
#import <GracenoteMusicID/GNSearchResult.h>
#import <GracenoteMusicID/GNSearchResponse.h>
#import <GracenoteMusicID/GNAudioSourceMic.h>
#import <GracenoteMusicID/GNRecognizeStream.h>

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

@interface AppDelegate : UIResponder <UIApplicationDelegate, CBPeripheralManagerDelegate, MCNearbyServiceAdvertiserDelegate, MCSessionDelegate, GNSearchResultReady, GNAudioSourceDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) CBPeripheralManager *peripheralManager;
@property (weak, nonatomic) MPMusicPlayerController *musicPlayerController;

@property (strong,nonatomic) MCSession* mcsession;
@property (strong,nonatomic) MCPeerID *peerID;

-(void)fileSearchResultReceived:(GNSearchResult*) fileSearchResult;
-(void)fingerprintSearchResultReceived:(GNSearchResult*) fingerprintSearchResult;
-(void)trackidSearchResultReceived:(GNSearchResult*) trackidSearchResult;

//Core Data Properties.
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end
