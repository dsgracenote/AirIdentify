//
//  AppDelegate.m
//  AirIdentifyClient
//
//  Created by Kshitij Deshpande on 7/30/13.
//  Copyright (c) 2013 Gracenote. All rights reserved.
//

#import "AppDelegate.h"
#import "AudioFileSearchResult.h"
#import "FingerprintSearchResult.h"

#import <GracenoteMusicID/GNSearchResponse.h>
#import <GracenoteMusicID/GNCoverArt.h>
#import <GracenoteMusicID/GNImage.h>
#import <Social/Social.h>
#import <Accounts/Accounts.h>

#import "MediaPlayer/MPMoviePlayerController.h"

@interface AppDelegate()

@property (strong, nonatomic) NSMutableDictionary *regionsAlreadyEntered;

@property (strong) MCPeerID *peerID;
@property (strong) MCNearbyServiceBrowser *browser;

@property (strong, nonatomic) GNRecognizeStream *recognizeStream;
@property (strong, nonatomic) GNAudioSourceMic *audioSourceMic;

@property (strong,nonatomic) MCSession* mcsession;

@property (strong, nonatomic) NSMutableDictionary *connectedPeers;

@property (strong, nonatomic) AudioFileSearchResult *audioFileSearchResult;

@property (strong, nonatomic) FingerprintSearchResult *fingerprintSearchResult;

@property (strong, nonatomic) GNSearchResponse *recentlyIdentifiedTrackResponse;

@property (strong) MPMoviePlayerController* moviePlayerController;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    self.moviePlayerController = [[MPMoviePlayerController alloc] init];
    
    [application setIdleTimerDisabled:YES];
    
    self.audioFileSearchResult = [[AudioFileSearchResult alloc] init];
    self.fingerprintSearchResult = [[FingerprintSearchResult alloc] init];
    
    [self configureAudioSessionAndStartRecording];
    
    self.regionsAlreadyEntered = [NSMutableDictionary dictionaryWithCapacity:10];
    
    self.musicPlayerController = [MPMusicPlayerController iPodMusicPlayer];
    [self.musicPlayerController beginGeneratingPlaybackNotifications];
    
    self.locationManager = [[CLLocationManager alloc] init];
    
    NSSet* monitoredRegions  = self.locationManager.monitoredRegions;
    for(CLRegion* region in monitoredRegions)
    {
        [self.locationManager stopMonitoringForRegion:region];
    }
    
    self.locationManager.delegate = self;
    
    self.peerID = [[MCPeerID alloc] initWithDisplayName:[UIDevice currentDevice].name];
    self.mcsession = [[MCSession alloc] initWithPeer:self.peerID securityIdentity:nil encryptionPreference:MCEncryptionOptional];
    self.mcsession.delegate = self;
    
    self.connectedPeers = [NSMutableDictionary dictionaryWithCapacity:2];
    
    self.accountStore = [[ACAccountStore alloc] init];
    
    if ([self userHasAccessToTwitter])
    {
        
        //  Step 1:  Obtain access to the user's Twitter accounts
        ACAccountType *twitterAccountType = [self.accountStore
                                             accountTypeWithAccountTypeIdentifier:
                                             ACAccountTypeIdentifierTwitter];
        
        [self.accountStore
         requestAccessToAccountsWithType:twitterAccountType
         options:NULL
         completion:^(BOOL granted, NSError *error)
         {
             if (granted)
             {
                 //  Step 2:  Create a request
                 NSArray *twitterAccounts =
                 [self.accountStore accountsWithAccountType:twitterAccountType];
                 
                 self.twitterAccount = [twitterAccounts lastObject];
                 
                 NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/home_timeline.json"];
                 
                 SLRequest *request =
                 [SLRequest requestForServiceType:SLServiceTypeTwitter
                                    requestMethod:SLRequestMethodGET
                                              URL:url
                                       parameters:nil];
                 
                 //  Attach an account to the request.
                 
                 [request setAccount:[twitterAccounts lastObject]];
                 
                 /*
                  //  Step 3:  Execute the request.
                  
                  [request performRequestWithHandler:^(NSData *responseData,
                  NSHTTPURLResponse *urlResponse,
                  NSError *error)
                  {
                  
                  if (responseData)
                  {
                  
                  if (urlResponse.statusCode >= 200 && urlResponse.statusCode < 300)
                  {
                  NSError *jsonError;
                  NSArray *userTimelineArray =
                  [NSJSONSerialization
                  JSONObjectWithData:responseData
                  options:NSJSONReadingAllowFragments error:&jsonError];
                  
                  
                  if (userTimelineArray)
                  {
                  
                  NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:TWITTERSOURCE, @"source" , userTimelineArray , @"data",nil];
                  [self.dataHandler addTask:dictionary];
                  
                  
                  }
                  }
                  else
                  {
                  // The server did not respond successfully... were we rate-limited?
                  NSLog(@"The response status code is %d", urlResponse.statusCode);
                  }
                  }
                  
                  }];
                  */
             }
         }];
    }
    
    [self startMonitoringForAllRegions];
    
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


-(void) identifyCurrentlyPlayingAudio
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
   }
   else if([audioSession isOtherAudioPlaying])
   {
       NSError *error = nil;

       if([audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error])
       {
           [audioSession setActive:YES error:nil];
           [self.recognizeStream idNow];
       }
   }
}

-(void) identifyAudioPlayingOniBeaconFromFingerprint:(NSString*) fingerprint
{
    GNConfig *config = [GNConfig init:CLIENTID];
  
    [GNOperations searchByFingerprint:self.fingerprintSearchResult config:config fingerprintData:fingerprint];
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
    
    if (err)
    {
        NSLog(@"ERROR: %@",[err localizedDescription]);
    }
}

#pragma mark - Fingerprint Search Result Received

-(void)fingerprintSearchResultReceived:(GNSearchResult*) fingerprintSearchResult
{
    // Now that we have this, transmit it to our connected peer through MultipeerNetworking.
    GNSearchResponse *response = fingerprintSearchResult.bestResponse;
    
    self.recentlyIdentifiedTrackResponse = response;
    
    NSDictionary *infoDict = @{@"track-title":[response trackTitle], @"album-title":response.albumTitle, @"track-duration":response.trackDuration, @"artist":response.artist, @"coverart-url":(response.coverArt && response.coverArt.data)?[response.coverArt data]:[NSNull null]};
    
        NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject:infoDict];
    
        self.currentlyPlayingTrackID = fingerprintSearchResult.bestResponse.trackId;
    
        [self.guidelegate displayCurrentlyPlayingTrackWithData:archivedData];
    
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

#pragma mark - GNSearchResultReady IDNOW/Mic Delegate Methods

- (void) GNResultReady:(GNSearchResult*)result
{
    //Since we have the response, send it back to original output.
    NSError *error = nil;
    
    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&error];
     
     if(error)
     {
         NSLog(@"error = %@",error.localizedDescription);
     }
    
    
    if(result && result.responses && result.responses>0)
    {
        [self sendSearchResultToConnectedPeers:result];
    }
}

#pragma mark - iBeacons and Core-Location Methods

-(void) startMonitoringForAllRegions
{
    for(int i=CARDIO_BEACON_TYPE;i<=CYCLING_BEACON_TYPE;i++)
    {
        NSArray* regions = [self regionsForServiceType:i];
        
        for(CLBeaconRegion *beaconRegion in regions)
        {
             NSLog(@"beaconRegion = %@", beaconRegion);
            
            [self.locationManager startMonitoringForRegion:beaconRegion];
        }
    }
    
}

-(NSArray*) regionsForServiceType:(NSUInteger) serviceType
{
    CLBeaconRegion* region = nil;
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:3];
    
    for(int i=SITTING_BEACON_TYPE;i<=RUNNING_BEACON_TYPE;i++)
    {
        NSString* str = [self serviceTypeFromSelection:serviceType specificServiceType:i];
        
        region = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString: AIRIDENTIFY_UUID] major:serviceType minor:i identifier:str];
        region.notifyOnEntry = YES;
        region.notifyOnExit = YES;
        region.notifyEntryStateOnDisplay = YES;
        
        [array addObject:region];
    }
    
    return array;
}


-(NSString*) serviceTypeFromSelection:(NSUInteger)serviceType specificServiceType:(NSUInteger )specificServiceType
{
    NSString *peerDisplayName = nil;
    NSString *specificServiceTypeString = nil;
    
    switch (serviceType)
    {
        case CARDIO_BEACON_TYPE:
            peerDisplayName = @"Cardio";
            break;
        case WEIGHTS_BEACON_TYPE:
            peerDisplayName = @"Weights";
            break;
        case TRAINING_BEACON_TYPE:
            peerDisplayName = @"Training";
            break;
        case YOGA_BEACON_TYPE:
            peerDisplayName = @"Yoga";
            break;
        case CROSSTRAINING_BEACON_TYPE:
            peerDisplayName = @"CrossTraining";
            break;
        case CYCLING_BEACON_TYPE:
            peerDisplayName = @"Cycling";
            break;
            
    }
    
    
    switch (specificServiceType)
    {
        case SITTING_BEACON_TYPE:
            specificServiceTypeString = @"Sedentary";
            break;
        case WALKING_BEACON_TYPE:
            specificServiceTypeString = @"Walking";
            break;
        case RUNNING_BEACON_TYPE:
            specificServiceTypeString = @"Runnning";
            break;
    }
    
    NSString *combinedString = [NSString stringWithFormat:@"%@%@",[peerDisplayName substringToIndex:4], [specificServiceTypeString substringToIndex:4]];
    
    NSString *truncatedString = [combinedString substringToIndex:7];
    
    NSLog(@"trucStr = %@", truncatedString);
    
    return [NSString stringWithFormat:@"airid-%@", truncatedString];
}


-(void) sendSearchResultToConnectedPeers:(GNSearchResult*) result
{
    NSError *error = nil;
    NSDictionary *resultsDictionary = @{@"fingerprint":result.fingerprintData, @"peerName":[UIDevice currentDevice].name};
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:resultsDictionary];
    
    [self.mcsession sendData:data toPeers:[self.mcsession connectedPeers] withMode:MCSessionSendDataReliable error:&error];
}

- (void)sendSelectedTrackToConnectedPeers {
    NSError *error = nil;
    NSDictionary *resultsDictionary = @{@"track-id":self.currentlyPlayingTrackID, @"user-id":self.twitterAccount.identifier, @"user-name":self.twitterAccount.username};
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:resultsDictionary];
    
    [self.mcsession sendData:data toPeers:[self.mcsession connectedPeers] withMode:MCSessionSendDataReliable error:&error];
}

-(void) searchCurrentlyIdentifiedTrackOnYouTube
{
    
    
}

-(void) fetchPopularVideosFromYouTube:(BOOL) continueFromLastFetch
{
    NSString *queryString = [NSString stringWithFormat:@"%@ %@",self.recentlyIdentifiedTrackResponse.trackTitle, self.recentlyIdentifiedTrackResponse.artist ];
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:queryString,@"q",@"json", @"alt", [NSNumber numberWithInteger:5] ,@"max-results", [NSNumber numberWithInteger:2],@"v",nil];
    
    NSURLRequest *fetchRequest = [self generateFetchRequestFromURL:@"https://gdata.youtube.com/feeds/api/videos" parameters:parameters];
    
    
    [NSURLConnection sendAsynchronousRequest:fetchRequest queue:[NSOperationQueue mainQueue] completionHandler: (^(NSURLResponse* response, NSData* data, NSError*error)
    {
                                                                                                                     
        NSError *jsonError;
        NSDictionary *popularVideosData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
        if(popularVideosData)
        {
            NSArray *entries = [popularVideosData valueForKeyPath:@"feed.entry"];
            
            [self parseYouTubeVideoSearchData:entries];
            
            NSLog(@"Result: %@", entries);
         }
         else
         {
          // Our JSON deserialization went awry
          NSLog(@"JSON Error: %@", [jsonError localizedDescription]);
         }
      }
    )];
}

-(NSURLRequest*) generateFetchRequestFromURL:(NSString*) URLString parameters:(NSDictionary*) params
{
    NSMutableString* string = [NSMutableString stringWithString:[NSString stringWithFormat:@"%@?", URLString ] ];
    NSUInteger count = 1;
    
    for(NSString *key in params)
    {
        id value = [params objectForKey:key];
        NSString *stringValue = nil;
        if([value isKindOfClass:[NSNumber class]])
        {
            stringValue = [((NSNumber*)value) stringValue];
        }
        else if([value isKindOfClass:[NSString class]])
        {
            stringValue = value;
        }
        
        if(count==1)
        {
            [string appendString: [NSString stringWithFormat:@"%@=%@",key, stringValue]];
        }
        else
        {
            [string appendString: [NSString stringWithFormat:@"&%@=%@",key, stringValue]];
        }
        
        count++;
    }
    
    NSURLRequest *fetchRequest =  [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:string]];
    
    return fetchRequest;
}

#pragma mark - Youtube Parsing API's 

-(void) parseYouTubeVideoSearchData:(id) inData
{

    if(!inData)
        return;
    
    NSArray *arrayData = nil;
    if([inData isKindOfClass:[NSArray class]])
    {
        arrayData = inData;
    }
    else
    {
        return;
    }
    
    NSUInteger count = 1;
    for(NSDictionary* data in arrayData)
    {
        ++count;
        
        for (NSString *key in data)
        {
            id value = [data objectForKey:key];
            
            if([key isEqualToString:@"id"])
            {
                if([value isKindOfClass:[NSDictionary class] ])
                {
                    NSDictionary *dictValue = value;
                    NSString *idValue = [dictValue objectForKey:@"$t"];
                    NSLog(@"idValue = %@", idValue);
                }
            }
            else if([key isEqualToString:@"title"])
            {
                if([value isKindOfClass:[NSDictionary class] ])
                {
                    NSDictionary *dictValue = value;
                    NSString *titleValue = [dictValue objectForKey:@"$t"];
                    NSLog(@"titleValue = %@", titleValue);
                }
            }
            else if([key isEqualToString:@"media$group"])
            {
                for(NSString *key in value)
                {
                    id propertyValue = [data objectForKey:key];
                    
                    if([key isEqualToString:@"media$player"])
                    {
                        if([propertyValue isKindOfClass:[NSDictionary class]])
                        {
                            NSString *strURL = [propertyValue objectForKey:@"url"];
                            
                            [self performSelectorOnMainThread:@selector(startPlayingVideoURL:) withObject:strURL waitUntilDone:NO];
                        }
                    }
                }
            }
        }
    }
}


-(void) startPlayingVideoURL:(NSString*) URLString
{
    
}

#pragma mark - MCNearbyServiceBrowser Delegate Methods

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    NSLog(@"Found Music Peer - %@ info:", peerID);
    [browser invitePeer:peerID toSession:self.mcsession withContext:nil timeout:30];
}


- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    NSLog(@"Lost connection to peer-%@", peerID);
}


#pragma mark - CLLocationManagerDelegate Methods 

/*- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    
    NSArray *immediateBeacons = [beacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", CLProximityImmediate]];
    
    if([immediateBeacons count])
    {
        if(![self.regionsAlreadyEntered objectForKey:region.identifier])
        {
          self.browser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.peerID serviceType:region.identifier];
        
          [self.browser startBrowsingForPeers];
            
          [self.regionsAlreadyEntered removeAllObjects];
            
          [self.regionsAlreadyEntered setObject:region forKey:[region identifier]];
            
        }
    }
    
}*/


- (void)locationManager:(CLLocationManager *)manager
      didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    if(state==CLRegionStateInside)
    {
        if(![self.regionsAlreadyEntered objectForKey:region.identifier])
        {
            [self.regionsAlreadyEntered removeAllObjects];
            
            [self.regionsAlreadyEntered setObject:region forKey:[region identifier]];
            
            if(self.browser)
            {
               [self.browser stopBrowsingForPeers];
                self.browser = nil;
            }
            
            self.browser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.peerID serviceType:region.identifier];
            
            [self.browser startBrowsingForPeers];
            self.browser.delegate = self;
            
            NSLog(@"Inside Region");
        }
    }
    else if(state==CLRegionStateOutside)
    {
        if([self.regionsAlreadyEntered objectForKey:region.identifier])
        {
            [self.regionsAlreadyEntered removeAllObjects];
        }
        
        NSLog(@"Outside Region");
    }
}


#pragma mark - MCSessionDelegate Methods

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    switch (state)
    {
        case MCSessionStateConnected:
            if(![self.connectedPeers objectForKey:peerID.displayName])
            {
                [self.connectedPeers setObject:peerID forKey:peerID.displayName];
                
                [self identifyCurrentlyPlayingAudio];
            }
            break;
        case MCSessionStateNotConnected:
            if([self.connectedPeers objectForKey:peerID.displayName])
            {
                [self.connectedPeers removeObjectForKey:peerID.displayName];
            }
            break;
            
        default:
            break;
    }
}

- (BOOL)userHasAccessToTwitter
{
    return [SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter];
}



// Received data from remote peer
- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    NSDictionary *userInfoDictionary = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    NSLog(@"Received data %@", userInfoDictionary);
    
    NSString *fingerprint = [userInfoDictionary objectForKey:@"fingerprint"];
    NSString *peerName = [userInfoDictionary objectForKey:@"peerName"];
    
    [self identifyAudioPlayingOniBeaconFromFingerprint:fingerprint];
    
    
}


#pragma mark - Miscellaneous Methods

-(NSString *)unescapeString:(NSString *)string
{
    // will cause trouble if you have "abc\\\\uvw"
    // \u   --->    \U
    NSString *esc1 = [string stringByReplacingOccurrencesOfString:@"\\u" withString:@"\\U"];
    
    // "    --->    \"
    NSString *esc2 = [esc1 stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    
    // \\"  --->    \"
    NSString *esc3 = [esc2 stringByReplacingOccurrencesOfString:@"\\\\\"" withString:@"\\\""];
    
    NSString *quoted = [[@"\"" stringByAppendingString:esc3] stringByAppendingString:@"\""];
    NSData *data = [quoted dataUsingEncoding:NSUTF8StringEncoding];
    
    //  NSPropertyListFormat format = 0;
    //  NSString *errorDescr = nil;
    NSString *unesc = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
    
    if ([unesc isKindOfClass:[NSString class]]) {
        // \U   --->    \u
        return [unesc stringByReplacingOccurrencesOfString:@"\\U" withString:@"\\u"];
    }
    
    return nil;
}

-(void) loadContentFromIdURLString:(NSString*) idURLString
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:idURLString]];
    [request setValue:(NSString *)kUserAgent forHTTPHeaderField:@"User-Agent"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:(^(NSURLResponse* response, NSData *data, NSError* error)
      {
        __block NSString *htmlString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSString *JSONStart = nil;
        NSString *JSONStartFull = @"ls.setItem('PIGGYBACK_DATA', \")]}'";
        NSString *JSONStartShrunk = [JSONStartFull stringByReplacingOccurrencesOfString:@" " withString:@""];
        if ([htmlString rangeOfString:JSONStartFull].location != NSNotFound)
        {
           JSONStart = JSONStartFull;
        }
        else if ([htmlString rangeOfString:JSONStartShrunk].location != NSNotFound)
        {
         JSONStart = JSONStartShrunk;
        }
        if (JSONStart != nil)
        {
           NSScanner* scanner = [NSScanner scannerWithString:htmlString];
           [scanner scanUpToString:JSONStart intoString:nil];
               [scanner scanString:JSONStart intoString:nil];
            
           NSString *JSON = nil;
           [scanner scanUpToString:@"\");" intoString:&JSON];
           JSON = [self unescapeString:JSON];
           NSError* decodingError = nil;
           NSDictionary* JSONCode = nil;
           
           JSONCode = [NSJSONSerialization JSONObjectWithData:[JSON dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&decodingError];
           
           if (decodingError)
           {
               error = decodingError;
           }
           else
           {
               NSArray* videos = [[[JSONCode objectForKey:@"content"] objectForKey:@"video"] objectForKey:@"fmt_stream_map"];
               NSString* streamURL = nil;
               if (videos.count)
               {
                   NSUInteger maxQuality = YouTubeVideoQualitySmall;
                   for(NSDictionary* dict in videos)
                   {
                       id quality = [dict objectForKey:@"quality"];
                       NSNumber *videoQuality = nil;
                       if([quality isKindOfClass:[NSString class]])
                           videoQuality = [NSNumber numberWithInteger:[quality integerValue]];
                       else
                           videoQuality = quality;
                       
                       if(videoQuality.integerValue>maxQuality)
                       {
                           maxQuality = videoQuality.integerValue;
                           streamURL = [dict objectForKey:@"url"];
                       }
                       else if(streamURL==nil)
                       {
                           streamURL = [dict objectForKey:@"url"];
                       }
                       
                   }
                   
               }
               
               if (streamURL)
               {
                   [self performSelectorOnMainThread:@selector(startPlaybackWithStreamURL:) withObject:streamURL waitUntilDone:YES ];
               }
               else
               {
                   error = [NSError errorWithDomain:@"YouTubePlayerExtractorErrorDomain" code:2 userInfo:[NSDictionary dictionaryWithObject:@"Couldn't find the stream URL." forKey:NSLocalizedDescriptionKey]];
               }
           }
       }
       else
       {
           error = [NSError errorWithDomain:@"YouTubePlayerExtractorErrorDomain" code:3 userInfo:[NSDictionary dictionaryWithObject:@"The JSON data could not be found." forKey:NSLocalizedDescriptionKey]];
       }
       
       
   })];
    
}


-(void) startPlaybackWithStreamURL:(NSString*) streamURLString
{
    [self.musicPlayerController stop];
    
    NSString *escapedStr = [streamURLString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding ];
    [self.moviePlayerController setContentURL:[NSURL URLWithString:escapedStr]];
    [self.moviePlayerController prepareToPlay];
    //[self.moviePlayerController setFullscreen:YES animated:NO];
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:escapedStr]] queue:[NSOperationQueue mainQueue] completionHandler:  ^(NSURLResponse *response, NSData *data, NSError* error){
        
        NSLog(@"Got data with length %ld", (unsigned long)data.length);
        
    }];
    
    [self.moviePlayerController play];
}

@end
