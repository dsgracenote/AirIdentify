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
        
    }
    
    if([((AppDelegate*)[UIApplication sharedApplication].delegate).musicPlayerController playbackState]== MPMoviePlaybackStatePlaying)
        [self.playButton setImage:[UIImage imageNamed:UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad?@"btn_pause_ipad" :@"player_bt_pause"] forState:UIControlStateNormal];
    else
        [self.playButton setImage:[UIImage imageNamed:UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad?@"btn_play_ipad":@"player_bt_play"] forState:UIControlStateNormal];
    
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
    __block CGRect rect = CGRectMake(self.currentlyPlayingInfoLabel.frame.origin.x, self.currentlyPlayingInfoLabel.frame.origin.y, expectedLabelSize.width, expectedLabelSize.height);
    self.currentlyPlayingInfoLabel.frame = rect;
    
    self.thumbsDownButton.hidden = NO;
    self.thumbsUpButton.hidden = NO;
    
    [UIView animateWithDuration:15.0 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationRepeatCount:3];
        rect.origin.x = -1 * (self.currentlyPlayingInfoLabel.frame.size.width);
        self.currentlyPlayingInfoLabel.frame = rect;
    } completion:^(BOOL finished){
        self.thumbsUpButton.hidden = YES;
        self.thumbsDownButton.hidden = YES;
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
    [appDelegate sendSelectedTrackToConnectedPeers];
}

- (IBAction)thumbsDownSelection:(id)sender{
 //   AppDelegate *appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
//    [appDelegate sendSelectedTrackToConnectedPeers];
}

@end
