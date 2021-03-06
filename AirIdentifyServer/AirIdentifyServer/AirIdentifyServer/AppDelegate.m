//
//  AppDelegate.m
//  AirIdentifyServer
//
//  Created by Kshitij Deshpande on 7/29/13.
//  Copyright (c) 2013 Gracenote. All rights reserved.
//

#import "AppDelegate.h"
#import "AudioFileSearchResult.h"
#import "FingerprintSearchResult.h"
#import "TextSearchResult.h"
#import "TrackIDSearchResult.h"

#import <GracenoteMusicID/GNSearchResponse.h>
#import <GracenoteMusicID/GNCoverArt.h>
#import <GracenoteMusicID/GNImage.h>
#import <GracenoteMusicID/GNOperations.h>

#import <CoreData/CoreData.h>
#import  "User.h"
#import "TrackInfo.h"
#import "TrackHistory.h"

@interface AppDelegate()

@property (strong, nonatomic) NSMutableDictionary *connectedClients;

@property (strong, nonatomic) NSMutableDictionary *userInfoForTrackIDDict;

@property (strong, nonatomic) NSMutableArray *peerIDsToSendRecommendations;
@property (strong, nonatomic) NSMutableArray *userIDsReceivedInContext;

@property (strong, nonatomic) GNRecognizeStream *recognizeStream;
@property (strong, nonatomic) GNAudioSourceMic *audioSourceMic;

@property (strong, nonatomic) AudioFileSearchResult *audioFileSearchResult;
@property (strong, nonatomic) FingerprintSearchResult *fingerprintSearchResult;
@property (strong, nonatomic) TextSearchResult *textSearchResult;

@property(strong, nonatomic) TrackIDSearchResult *trackIDSearchResult;

@end

@implementation AppDelegate

@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [application setIdleTimerDisabled:YES];
    
    [self configureAudioSessionAndStartRecording];
    
    self.musicPlayerController = [MPMusicPlayerController iPodMusicPlayer];
    [self.musicPlayerController beginGeneratingPlaybackNotifications];
    
    self.mcsession = nil;
    
    self.peerID = nil;
    
    self.connectedClients = [NSMutableDictionary dictionaryWithCapacity:10];
    self.userInfoForTrackIDDict = [NSMutableDictionary dictionaryWithCapacity:10];
    self.peerIDsToSendRecommendations = [NSMutableArray arrayWithCapacity:10];
    self.userIDsReceivedInContext = [NSMutableArray arrayWithCapacity:10];
    
    self.audioFileSearchResult = [[AudioFileSearchResult alloc] init];
    self.fingerprintSearchResult = [[FingerprintSearchResult alloc] init];
    self.trackIDSearchResult = [[TrackIDSearchResult alloc] init];
    self.textSearchResult = [[TextSearchResult alloc] init];

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


-(void) identifyAudioPlayingOnClientDeviceFromFingerprint:(NSString*) fingerprint
{
    GNConfig *config = [GNConfig init:CLIENTID];
    
    [GNOperations searchByFingerprint:self.fingerprintSearchResult config:config fingerprintData:fingerprint];
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
        
        NSLog(@"archivedData = %@", archivedData);
    }
    
}

#pragma mark - Text Search Result Received

-(void)textSearchResultReceived:(GNSearchResult*) textSearchResult
{
    NSMutableArray *recos = [NSMutableArray arrayWithCapacity:10];
    
    NSArray *responses = textSearchResult.responses;
    for(GNSearchResponse *response in responses)
    {
    
        id coverArtData = [response.coverArt data];
        if(!coverArtData)
            coverArtData = [NSNull null];
        
        id trackDuration = [NSNull null];
        id albumTitle = [NSNull null];
        id trackTitle = [NSNull null];
        id artist = [NSNull null];
        
        if(response.trackDuration)
            trackDuration = response.trackDuration;
        
        if(response.albumTitle)
            albumTitle = response.albumTitle;
        
        if(response.trackTitle)
            trackTitle = response.trackTitle;
        
        if(response.artist)
            artist = response.artist;
            
        
        NSDictionary *infoDict = @{@"track-title":trackTitle, @"album-title":albumTitle, @"track-duration":trackDuration, @"artist":artist, @"coverart-url":coverArtData};
        
        NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject:infoDict];
        
        [recos addObject:archivedData];
    }

    NSData *archivedArray = [NSKeyedArchiver archivedDataWithRootObject:recos];
    NSDictionary *dictionaryToSend = @{@"recommendations":@"YES", @"data":archivedArray };
    NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject:dictionaryToSend];
    
    NSError *error = nil;
    
    
    [self.mcsession sendData:archivedData toPeers:self.peerIDsToSendRecommendations withMode:MCSessionSendDataReliable error:&error];
    
    NSLog(@"self.peerIDsToSendRecommendations = %@", self.peerIDsToSendRecommendations);
    
    if(error)
    {
        NSLog(@"Error sending recos = %@",error.localizedDescription);
    }
    
}



-(void) identifyAudioPlayingOnClientDeviceFromTrackId:(NSString*) trackID
{
    GNConfig *config = [GNConfig init:CLIENTID];
    
    [GNOperations fetchByTrackId:self.trackIDSearchResult config:config trackId:trackID];
}

#pragma mark - TrackID Search Result Received

-(void)trackidSearchResultReceived:(GNSearchResult*) trackidSearchResult
{
    [self addUserInfoToDB:trackidSearchResult];
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

- (void) sendUpdateToPeers:(NSDictionary*)resultsDict {
    
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
    
    NSDictionary *contextDictionary = nil;
    
    if(context)
    {
        contextDictionary =  [NSKeyedUnarchiver unarchiveObjectWithData:context];
        if(contextDictionary.count)
           [self.userIDsReceivedInContext addObject:[contextDictionary objectForKey:@"user-id"]];
        
        [self.peerIDsToSendRecommendations removeAllObjects];
    }
}

-(void) fetchHistoryForUser:(NSString*) userID
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:self.managedObjectContext];
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchBatchSize:25];
    
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"userID==%@", userID];
    
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"userID" ascending:YES]];
    
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    
    [fetchedResultsController performFetch:nil];
    
    if([fetchedResultsController fetchedObjects].count)
    {
        User *user = [[fetchedResultsController fetchedObjects] lastObject];
        NSSet *trackInfo = user.trackhistory.trackinfo;
        NSArray *trackInfoArray = [trackInfo allObjects];
        trackInfoArray = [trackInfoArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"iBeaconID==%@", self.peerID.displayName]];
        
        NSMutableDictionary *artistDict = [NSMutableDictionary dictionaryWithCapacity:10];
        for(TrackInfo* trackinfoObj in trackInfoArray)
        {
            NSNumber *artistFrequency = [artistDict objectForKey:trackinfoObj.artistName];
            
            [artistDict setObject:artistFrequency?[NSNumber numberWithInteger:artistFrequency.integerValue+1]:[NSNumber numberWithInteger:1] forKey:trackinfoObj.artistName];
            
            
        }
        
        NSArray *sortedKeys = nil;
        
        if(artistDict.count>1)
        {
         sortedKeys = [artistDict keysSortedByValueUsingComparator: ^(id obj1, id obj2)
         {
            
            if ([obj1 integerValue] > [obj2 integerValue]) {
                return (NSComparisonResult)NSOrderedDescending;
            }
            
            if ([obj1 integerValue] < [obj2 integerValue]) {
                return (NSComparisonResult)NSOrderedAscending;
            }
            return (NSComparisonResult)NSOrderedSame;
          }];
        }
        else
        {
            sortedKeys = [NSArray arrayWithObject:[[artistDict allKeys] objectAtIndex:0]];
        }
        
        NSString *mostListenedArtist = nil;
        
        if(sortedKeys.count)
        {
            mostListenedArtist =  [sortedKeys objectAtIndex:0];
            
            [self fetchTracksForArtist:mostListenedArtist];
        }
    }

}

-(void) fetchTracksForArtist:(NSString*)artist
{
    GNConfig *config = [GNConfig init:CLIENTID];
    [GNOperations searchByText:self.textSearchResult config:config artist:artist albumTitle:nil trackTitle:nil];
}

#pragma mark - MCSession Delegate Methods

// Received data from remote peer
- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    NSDictionary *userInfoDictionary = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    NSString *trackID = [userInfoDictionary objectForKey:@"track-id"];
    
    UILocalNotification *alert = [[UILocalNotification alloc] init];
    alert.alertBody = [NSString stringWithFormat:@"Received data from peer - %@", peerID.displayName ];
    [[UIApplication sharedApplication] presentLocalNotificationNow:alert];
    
    if(trackID)
    {
     [self.userInfoForTrackIDDict setObject:userInfoDictionary forKey:trackID];
     [self identifyAudioPlayingOnClientDeviceFromTrackId:trackID];
    }
    
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
            
            for(NSString *userID in self.userIDsReceivedInContext)
                [self fetchHistoryForUser:userID];
            
            [self.peerIDsToSendRecommendations addObject:peerID];
            
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


#pragma mark - Serializing Data to Core Data DB

-(void)addUserInfoToDB:(GNSearchResult*) trackidSearchResult
{
    NSLog(@"Adding UserInfo to DB");
    
    GNSearchResponse *bestResponse = trackidSearchResult.bestResponse;
    
    NSDictionary *userInfoDictionary = [self.userInfoForTrackIDDict objectForKey:bestResponse.trackId];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:self.managedObjectContext];
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchBatchSize:25];
    
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"userID==%@", [userInfoDictionary objectForKey:@"user-id"]];
    
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"userID" ascending:YES]];
    
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    
    [fetchedResultsController performFetch:nil];
    
    if([fetchedResultsController fetchedObjects].count)
    {
       User *user = [[fetchedResultsController fetchedObjects] lastObject];
       NSSet *trackIDSet = [user.trackhistory valueForKeyPath:@"trackinfo.trackID"];
       NSArray *trackIDs = [trackIDSet allObjects];
       trackIDs = [trackIDs filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self==%@",bestResponse.trackId]];
        
        if(trackIDs.count==0)
        {
            TrackInfo *trackInfoObject = [NSEntityDescription insertNewObjectForEntityForName:@"TrackInfo" inManagedObjectContext:self.managedObjectContext];
            
            trackInfoObject.trackID = bestResponse.trackId;
            trackInfoObject.trackTitle = bestResponse.trackTitle;
            trackInfoObject.albumName = bestResponse.albumTitle;
            trackInfoObject.artistName = bestResponse.artist;
            trackInfoObject.infoAddedDate = [NSDate date].timeIntervalSince1970;
            
            NSMutableSet *mutableSet = [NSMutableSet setWithSet:user.trackhistory.trackinfo];
            [mutableSet addObject:trackInfoObject];
            
            user.trackhistory.trackinfo = mutableSet;
        }
    }
    else
    {
       NSLog(@"Creating new User......");
        
       User *user = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:self.managedObjectContext];
        
        TrackHistory *trackHistory = [NSEntityDescription insertNewObjectForEntityForName:@"TrackHistory" inManagedObjectContext:self.managedObjectContext];
        
        user.userID = [userInfoDictionary objectForKey:@"user-id"];
        user.userName = [userInfoDictionary objectForKey:@"user-name"];
        user.twitter = [userInfoDictionary objectForKey:@"twitter"];
        
        
        TrackInfo *trackInfoObject = [NSEntityDescription insertNewObjectForEntityForName:@"TrackInfo" inManagedObjectContext:self.managedObjectContext];
        
        trackInfoObject.trackID = bestResponse.trackId;
        trackInfoObject.trackTitle = bestResponse.trackTitle;
        trackInfoObject.albumName = bestResponse.albumTitle;
        trackInfoObject.artistName = bestResponse.artist;
        trackInfoObject.iBeaconID = self.peerID.displayName;
        
        NSMutableSet *mutableSet = [NSMutableSet setWithSet:user.trackhistory.trackinfo];
        [mutableSet addObject:trackInfoObject];
        
        user.trackhistory = trackHistory;
        
        user.trackhistory.trackinfo = mutableSet;
        
    }
    
    [self saveContext];
    
}


#pragma mark - Core Data

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil)
    {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
        {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext != nil)
    {
        return __managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        __managedObjectContext = [[NSManagedObjectContext alloc] init];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return __managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel != nil)
    {
        return __managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return __managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (__persistentStoreCoordinator != nil)
    {
        return __persistentStoreCoordinator;
    }
    
    NSError *err = nil;
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Cafe.sqlite"];
    NSFileManager *mgr = [NSFileManager defaultManager];
    NSDictionary *attr = [mgr attributesOfItemAtPath:[storeURL path] error:&err];
    if(![[attr objectForKey:NSFileProtectionKey] isEqual:NSFileProtectionComplete])
    {
        attr = [NSDictionary dictionaryWithObject:NSFileProtectionComplete forKey:NSFileProtectionKey];
        [mgr setAttributes:attr ofItemAtPath:[storeURL path] error:&err];
    }
    
    NSError *error = nil;
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
        
        //Try doing a light weight migration.
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                                 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
        
        NSPersistentStore *store = [__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                                              configuration:nil URL:storeURL
                                                                                    options:options error:&error];
        
        if(!store)
        {
            // If light weight migration fails then delete the old DB.
            [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
        }
        
        
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        //NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        //abort();
    }    
    
    return __persistentStoreCoordinator;
}


#pragma mark - Application's Documents directory

/**
 Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
