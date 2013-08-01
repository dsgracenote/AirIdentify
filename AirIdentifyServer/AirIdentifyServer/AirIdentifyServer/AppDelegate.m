//
//  AppDelegate.m
//  AirIdentifyServer
//
//  Created by Kshitij Deshpande on 7/29/13.
//  Copyright (c) 2013 Gracenote. All rights reserved.
//

#import "AppDelegate.h"
#import "AudioFileSearchResult.h"

#import <GracenoteMusicID/GNSearchResponse.h>
#import <GracenoteMusicID/GNCoverArt.h>
#import <GracenoteMusicID/GNImage.h>
#import <GracenoteMusicID/GNOperations.h>

@interface AppDelegate()

@property (strong, nonatomic) NSMutableDictionary *connectedClients;

@property (strong, nonatomic) GNRecognizeStream *recognizeStream;
@property (strong, nonatomic) GNAudioSourceMic *audioSourceMic;

@property (strong, nonatomic) AudioFileSearchResult *audioFileSearchResult;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    [self configureAudioSessionAndStartRecording];
    
    self.musicPlayerController = [MPMusicPlayerController iPodMusicPlayer];
    [self.musicPlayerController beginGeneratingPlaybackNotifications];
    
    self.mcsession = nil;
    
    self.peerID = nil;
    
    self.connectedClients = [NSMutableDictionary dictionaryWithCapacity:10];
    
    self.audioFileSearchResult = [[AudioFileSearchResult alloc] init];

    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


#pragma mark - Fingerprint Search Result Received

-(void)fingerprintSearchResultReceived:(GNSearchResult*) fingerprintSearchResult
{
    // Now that we have this, transmit it to our connected peer through MultipeerNetworking.
    if([self.mcsession connectedPeers])
    {
        GNSearchResponse *response = fingerprintSearchResult.bestResponse;
        
        
        NSDictionary *infoDict = @{@"track-title":[response trackTitle], @"album-title":response.albumTitle, @"track-duration":response.trackDuration, @"artist":response.artist, @"coverart-url":[response.coverArt url]};
        
        NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject:infoDict];
        
    }
    
}

#pragma mark - File Search Result Received

-(void)fileSearchResultReceived:(GNSearchResult*) fileSearchResult
{
    // Now that we have this, transmit it to our connected peer through MultipeerNetworking.
    if([self.mcsession connectedPeers])
    {
        [self sendSearchResultToConnectedPeers:fileSearchResult];
    }
    
}

-(void) identifyCurrentPlayingAudioOniBeacon
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    if([self.musicPlayerController playbackState]==MPMusicPlaybackStatePlaying)
    {
        MPMediaItem *item = [self.musicPlayerController nowPlayingItem];
        NSURL *url = [item valueForProperty:MPMediaItemPropertyAssetURL];
       
        if(url)
        {
         GNConfig *config = [GNConfig init:CLIENTID];
         [GNOperations recognizeMIDFileFromFile:self.audioFileSearchResult config:config fileUrl:url];
        }
        else
        {
           [self.recognizeStream idNow];
        }
    }
    else if([audioSession isOtherAudioPlaying])
    {
      [self.recognizeStream idNow];
        
    }
}

-(void) sendCurrentlyPlayingAudioToPeer:(MCPeerID*) peerID
{
    //[self.mcsession sendData:<#(NSData *)#> toPeers:<#(NSArray *)#> withMode:<#(MCSessionSendDataMode)#> error:<#(NSError *__autoreleasing *)#>];
}


-(void) configureAudioSessionAndStartRecording
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionMixWithOthers  error:nil];
    
    GNAudioConfig *audioConfig = [GNAudioConfig gNAudioConfigWithSampleRate:44100 bytesPerSample:2 numChannels:1];
    
    self.audioSourceMic = [GNAudioSourceMic gNAudioSourceMic:audioConfig];
    self.audioSourceMic.delegate = self;
    
    GNConfig *config = [GNConfig init:CLIENTID];
    self.recognizeStream = [GNRecognizeStream gNRecognizeStream:config];
    [self.recognizeStream startRecognizeSession:self audioConfig:audioConfig];
    [self.audioSourceMic startRecording];
}

- (void) audioBufferDidBecomeReady:(GNAudioSource*)audioSource samples:(NSData*)samples {
    NSError *err;
    err = [self.recognizeStream writeBytes:samples];
    
    if (err) {
        NSLog(@"ERROR: %@",[err localizedDescription]);
    }
}

#pragma mark - CBPeripheralManager Delegate Methods

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    
}

#pragma mark - GNSearchResultReady IDNOW/Mic Delegate Methods

- (void) GNResultReady:(GNSearchResult*)result
{
    //Since we have the response, send it back to original output.
    NSError *error = nil;
    
    
    if(error)
    {
        NSLog(@"error = %@",error.localizedDescription);
    }
    
    
    if(result && result.responses && result.responses>0)
    {
        NSLog(@"Responses = %@", result.responses);
        [self sendSearchResultToConnectedPeers:result];
    }
    else
    {
        NSLog(@"Doing idNow again...");
        [self.recognizeStream idNow];
    }
}

-(void) sendSearchResultToConnectedPeers:(GNSearchResult*) result
{
    NSError *error = nil;
    NSDictionary *resultsDictionary = @{@"fingerprint":result.fingerprintData, @"peerName":[UIDevice currentDevice].name};
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:resultsDictionary];
    NSLog(@"Connected peers = %@",[self.mcsession connectedPeers] );
    [self.mcsession sendData:data toPeers:[self.mcsession connectedPeers] withMode:MCSessionSendDataReliable error:&error];
}


#pragma mark - MCNearbyAdvertizer Delegate

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void(^)(BOOL accept, MCSession *session))invitationHandler
{
    UILocalNotification *alert = [[UILocalNotification alloc] init];
    alert.alertBody = [NSString stringWithFormat:@"Did receive invitation from peer - %@", peerID.displayName ];
    [[UIApplication sharedApplication] presentLocalNotificationNow:alert];
    
    invitationHandler(YES, self.mcsession);
}

#pragma mark - MCSession Delegate Methods

// Received data from remote peer
- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    NSDictionary *userInfoDictionary = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    UILocalNotification *alert = [[UILocalNotification alloc] init];
    alert.alertBody = [NSString stringWithFormat:@"Received data from peer - %@", peerID.displayName ];
    [[UIApplication sharedApplication] presentLocalNotificationNow:alert];
    
    NSLog(@"Received data %@", userInfoDictionary);
      
}

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    switch (state) {
        case MCSessionStateConnected:
        {  if(![self.connectedClients objectForKey:peerID.displayName])
                [self.connectedClients setObject:peerID forKey:peerID.displayName];
            
            UILocalNotification *alert = [[UILocalNotification alloc] init];
            alert.alertBody = [NSString stringWithFormat:@"Connected to peer - %@", peerID.displayName ];
            [[UIApplication sharedApplication] presentLocalNotificationNow:alert];
            
            [self identifyCurrentPlayingAudioOniBeacon];
        }
            break;
        case MCSessionStateNotConnected:
            if(![self.connectedClients objectForKey:peerID.displayName])
                [self.connectedClients removeObjectForKey:peerID.displayName];
            break;
            
        default:
            break;
    }
}


@end
