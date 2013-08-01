//
//  FirstViewController.m
//  AirIdentifyServer
//
//  Created by Kshitij Deshpande on 7/29/13.
//  Copyright (c) 2013 Gracenote. All rights reserved.
//

#import "FirstViewController.h"
#import "AppDelegate.h"

@interface FirstViewController ()

@end

@implementation FirstViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    
    MPVolumeView *volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(5, 5, self.volumeBarView.frame.size.width-20, self.volumeBarView.frame.size.height-5)];
    
    [self.volumeBarView addSubview:volumeView];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nowPlayingItemDidChange:) name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nowPlayingItemDidChange:) name:MPMusicPlayerControllerPlaybackStateDidChangeNotification object:nil];
    
}

-(void) viewDidAppear:(BOOL)animated
{
    MPMediaItem *mediaItem = [((AppDelegate*)[UIApplication sharedApplication].delegate).musicPlayerController   nowPlayingItem];
    
    if(mediaItem)
    {
        MPMediaItemArtwork *artWork =  [mediaItem valueForKey:MPMediaItemPropertyArtwork];
        UIImage *image =  [artWork imageWithSize:self.imageView.frame.size];
        self.imageView.image = image;
        
    }
    
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

@end
