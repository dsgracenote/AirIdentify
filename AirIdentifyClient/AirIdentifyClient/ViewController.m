//
//  ViewController.m
//  AirIdentifyClient
//
//  Created by Kshitij Deshpande on 7/30/13.
//  Copyright (c) 2013 Gracenote. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import <Accounts/Accounts.h>
#import <Social/Social.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    AppDelegate *appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    
    MPVolumeView *volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(5, 5, self.volumeBarView.frame.size.width-20, self.volumeBarView.frame.size.height-5)];
    
    [self.volumeBarView addSubview:volumeView];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nowPlayingItemDidChange:) name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nowPlayingItemDidChange:) name:MPMusicPlayerControllerPlaybackStateDidChangeNotification object:nil];

	// Do any additional setup after loading the view, typically from a nib.
    CGRect rect = self.whatsPlayingView.frame;
    rect.origin.y = -1*rect.size.height;
    self.whatsPlayingView.frame = rect;
    
    [self.whatsPlayingView.layer setBorderColor:[UIColor blueColor].CGColor];
    [self.whatsPlayingView.layer setBorderWidth:2.0];
    [self.whatsPlayingView.layer setCornerRadius:5.0];
    
    self.currentlyPlayingInfoLabel.clipsToBounds = YES;
    self.currentlyPlayingParentView.clipsToBounds = YES;
    
    self.thumbsUpButton.hidden = YES;
    self.thumbsDownButton.hidden = YES;
    
    /*
    // Dummy data
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"test", @"artist", @"test-track", @"track-title",nil];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dictionary];
    [self displayCurrentlyPlayingTrackWithData:data];
    */
    

    [appDelegate setGuidelegate:self];
}


-(void) nowPlayingItemDidChange:(NSNotification*) notification
{
    MPMediaItem *mediaItem = [((AppDelegate*)[UIApplication sharedApplication].delegate).musicPlayerController   nowPlayingItem];
    AppDelegate* appDelegate = ((AppDelegate*)[UIApplication sharedApplication].delegate);
    
    if(mediaItem)
    {
        MPMediaItemArtwork *artWork =  [mediaItem valueForKey:MPMediaItemPropertyArtwork];
        UIImage *image =  [artWork imageWithSize:self.imageView.frame.size];
        self.imageView.image = image;
        
        NSString *title = [mediaItem valueForKey:MPMediaItemPropertyTitle];
        [self.trackTitleLabel setText:title];
        [self.trackTitleLabel setFont:[UIFont boldSystemFontOfSize:25.0]];
        [self.trackTitleLabel setTextAlignment:NSTextAlignmentCenter];
        
        NSString *artist = [mediaItem valueForKey:MPMediaItemPropertyArtist];
        [self.artistNameLabel setText:artist];
        [self.artistNameLabel setFont:[UIFont systemFontOfSize:15.0]];
        [self.artistNameLabel setTextAlignment:NSTextAlignmentCenter];
        
        if([title isEqualToString:appDelegate.currentlyPlayingTrackTitle] && [artist isEqualToString:appDelegate.currentlyPlayingTrackArtist] && appDelegate.currentlyPlayingTrackAdjustedSongPosition)
        {
            NSTimeInterval currentTimeInterval =  [NSDate date].timeIntervalSince1970;
            NSTimeInterval adjustedTimeInterval = [appDelegate.currentlyPlayingTrackAdjustedSongPosition doubleValue]/1000;
            
            adjustedTimeInterval+=currentTimeInterval;
            
            [appDelegate.musicPlayerController beginSeekingForward];
            
            while(appDelegate.musicPlayerController.currentPlaybackTime<adjustedTimeInterval);
            
            [appDelegate.musicPlayerController endSeeking];
                
        }
        
    }
    
    if([((AppDelegate*)[UIApplication sharedApplication].delegate).musicPlayerController playbackState]== MPMoviePlaybackStatePlaying)
        [self.playButton setImage:[UIImage imageNamed:UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad?@"btn_pause_ipad" :@"player_bt_pause"] forState:UIControlStateNormal];
    else
        [self.playButton setImage:[UIImage imageNamed:UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad?@"btn_play_ipad":@"player_bt_play"] forState:UIControlStateNormal];
    
}

- (IBAction)startStreaminAudio:(id)sender
{
    AppDelegate *appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    
    MPMediaQuery *query = [[MPMediaQuery alloc] init];
    
    [query addFilterPredicate: [MPMediaPropertyPredicate
                                predicateWithValue: appDelegate.currentlyPlayingTrackArtist
                                forProperty: MPMediaItemPropertyArtist]];
    
    // Sets the grouping type for the media query
    [query setGroupingType: MPMediaGroupingAlbum];
    
    NSArray *albums = [query collections];
    for (MPMediaItemCollection *album in albums) {
        MPMediaItem *representativeItem = [album representativeItem];
        NSString *artistName =
        [representativeItem valueForProperty: MPMediaItemPropertyArtist];
        NSString *albumName =
        [representativeItem valueForProperty: MPMediaItemPropertyAlbumTitle];
        NSLog (@"%@ by %@", albumName, artistName);
        
        NSArray *songs = [album items];
        for (MPMediaItem *song in songs)
        {
            NSString *songTitle =
            [song valueForProperty: MPMediaItemPropertyTitle];
            
            NSRange rng = [songTitle rangeOfString:@"("];
            if(rng.location!=NSNotFound)
            {
                songTitle = [songTitle substringToIndex:rng.location];
            }
            
            
            if([appDelegate.currentlyPlayingTrackTitle rangeOfString:songTitle].location!=NSNotFound)
            {
                NSLog (@"Starting to Stream and play\t\t%@", songTitle);
                [appDelegate startStreamingMediaItem:song];
                
            }
              NSLog (@"\t\t%@", songTitle);
        }
    }
}

- (IBAction)skipToNextItem:(id)sender
{
    [((AppDelegate*)[UIApplication sharedApplication].delegate).musicPlayerController skipToNextItem];
}

- (IBAction)skipToPreviousItem:(id)sender
{
    [((AppDelegate*)[UIApplication sharedApplication].delegate).musicPlayerController skipToPreviousItem];
}

- (IBAction)play:(id)sender
{
    if([((AppDelegate*)[UIApplication sharedApplication].delegate).musicPlayerController playbackState]== MPMoviePlaybackStatePlaying)
    {
        [((AppDelegate*)[UIApplication sharedApplication].delegate).musicPlayerController pause];
        [self.playButton setImage:[UIImage imageNamed:UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad?@"btn_pause_ipad" :@"player_bt_pause"] forState:UIControlStateNormal];
    }
    else
    {
        [((AppDelegate*)[UIApplication sharedApplication].delegate).musicPlayerController play];
        [self.playButton setImage:[UIImage imageNamed:UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad?@"btn_play_ipad":@"player_bt_play"] forState:UIControlStateNormal];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - GUIDelegate Methods

-(void) reloadHistoryTableView
{
    [self.historyTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO]; 
}

-(void) displayCurrentlyPlayingTrackWithData:(NSData*) data
{
    self.thumbsUpButton.enabled = YES;
    NSDictionary *unarchDictionary = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:data];
    self.currentlyPlayingArtistLabel.text = [unarchDictionary objectForKey:@"artist"];
    self.currentlyPlayingTrackTitleLabel.text = [unarchDictionary objectForKey:@"track-title"];
    
    NSLog(@"unarchDictionary=%@", unarchDictionary);
    
    if([unarchDictionary objectForKey:@"coverart-url"]!=[NSNull null])
    {
      self.currentlyPlayingCoverart.image = [UIImage imageWithData:[unarchDictionary objectForKey:@"coverart-url"]];
    }
    
    self.currentlyPlayingInfoLabel.text = [NSString stringWithFormat:@"%@/%@", [unarchDictionary objectForKey:@"track-title"], [unarchDictionary objectForKey:@"artist"]];
    
    
    CGSize expectedLabelSize = [self.currentlyPlayingInfoLabel.text sizeWithFont:self.currentlyPlayingInfoLabel.font
                                                               constrainedToSize:self.currentlyPlayingInfoLabel.frame.size
                                                                   lineBreakMode:self.currentlyPlayingInfoLabel.lineBreakMode];
    __block CGRect rect = CGRectMake(72, 23, expectedLabelSize.width, expectedLabelSize.height);
    self.currentlyPlayingInfoLabel.frame = rect;
    
    self.thumbsDownButton.hidden = NO;
    self.thumbsUpButton.hidden = NO;
    self.startStreamingButton.hidden = NO;
    
    [UIView animateWithDuration:10.0 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationRepeatCount:3];
        rect.origin.x = -1 * (self.currentlyPlayingInfoLabel.frame.size.width);
        self.currentlyPlayingInfoLabel.frame = rect;
    } completion:^(BOOL finished){
        if(finished)
        {
         self.thumbsUpButton.hidden = YES;
         self.thumbsDownButton.hidden = YES;
          self.startStreamingButton.hidden = YES;
        }
    }];
    
    /*
    __block CGRect rect = self.whatsPlayingView.frame;
    self.whatsPlayingView.hidden = NO;
    
    [UIView animateWithDuration:1.5 animations:^{
        rect.origin.y = 0;
        self.whatsPlayingView.frame = rect;
    }];
    
    
    [UIView animateWithDuration:0.5 delay:5.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        rect.origin.y = -1*rect.size.height;
        self.whatsPlayingView.frame = rect;
    } completion:nil];
    */
    
}


- (IBAction)thumbsUpSelection:(id)sender{
    AppDelegate *appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    [appDelegate sendSelectedTrackToConnectedPeers:YES];
}

- (IBAction)showListView:(id)sender
{
    __block CGRect mainrect = self.mainPlayerView.frame;
    
    if(self.historyView.hidden)
    {
    
      self.historyView.alpha = 0.0;
      self.historyView.hidden = NO;
        
        [UIView animateWithDuration:0.5 animations:
          ^{
            mainrect.origin.x+=mainrect.size.width/1.5;
            self.mainPlayerView.frame = mainrect;
            self.historyView.alpha = 0.8;
        
        
          } completion:^(BOOL finished){
          
              if(finished)
              {
                  [UIView setAnimationBeginsFromCurrentState:YES];
                  [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
                  //Animate table view.
                  CAKeyframeAnimation * anim = [ CAKeyframeAnimation animationWithKeyPath:@"transform" ] ;
                  anim.values = [ NSArray arrayWithObjects:
                                  [ NSValue valueWithCATransform3D:CATransform3DMakeTranslation(10.0f, 0.0f, 0.0f) ],
                                 [ NSValue valueWithCATransform3D:CATransform3DMakeTranslation(-5.0f, 0.0f, 0.0f) ],
                                 [ NSValue valueWithCATransform3D:CATransform3DMakeTranslation(0.0f, 0.0f, 0.0f) ],
                                 nil ] ;
                  anim.autoreverses = NO ;
                  anim.repeatCount = 0.0f ;
                  anim.duration = 0.5f ;
                  
                  [self.mainPlayerView.layer addAnimation:anim forKey:@"back-forth"];
                  
                self.historyView.alpha = 1.0; self.mainPlayerView.tintAdjustmentMode=UIViewTintAdjustmentModeDimmed;
              }
          
          
          }];
        
    }
    else
    {
        [UIView animateWithDuration:0.5 animations:
         ^{
             mainrect.origin.x=0;
             self.mainPlayerView.frame = mainrect;
             self.historyView.alpha = 0.0;
         } completion:^(BOOL finished){
             
             if(finished)
             {
              self.historyView.hidden=YES;
              self.mainPlayerView.tintAdjustmentMode=UIViewTintAdjustmentModeNormal;
             }
         
         }];

    }
    
    
}

- (IBAction)thumbsDownSelection:(id)sender{
    AppDelegate *appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    [appDelegate sendSelectedTrackToConnectedPeers:NO];
}


#pragma mark Table View Datasource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    AppDelegate *appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    
    if(section==0) //Display Recommendations.
       return [appDelegate.recommendationsArray count];
    else
        return [appDelegate.cachedTracks count];
    
    return 5;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    
    if(section==1)
        return @"Local History";
    
    return @"Recommendations";
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellIdentifier = @"CellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    AppDelegate *appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    
    if(!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    NSString *trackTitle = @"<Track Title>";
    NSString *artist = @"<Artist>";
    
    if(indexPath.section==0)
    { //It is THE Recos.
        
       NSDictionary *recommendationDict = [appDelegate.recommendationsArray objectAtIndex:indexPath.row];
        
        trackTitle = [recommendationDict objectForKey:@"track-title"];
        artist = [recommendationDict objectForKey:@"artist"];
    } else {
        NSDictionary *localTrackDict = [appDelegate.cachedTracks objectAtIndex:indexPath.row];
        trackTitle = [localTrackDict objectForKey:@"track-title"];
        artist = [localTrackDict objectForKey:@"artist"];
    }
    
    cell.textLabel.text = trackTitle;
    cell.detailTextLabel.text = artist;
    
    return cell;
}


@end
