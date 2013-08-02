//
//  ViewController.h
//  AirIdentifyClient
//
//  Created by Kshitij Deshpande on 7/30/13.
//  Copyright (c) 2013 Gracenote. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GUIDelegate.h"
#import <Accounts/Accounts.h>

@interface ViewController : UIViewController<GUIDelegate, UITableViewDataSource, UITableViewDelegate>


@property (strong, nonatomic) IBOutlet UIView *volumeView;
@property (strong, nonatomic) IBOutlet UIButton *playButton;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UIView *volumeBarView;
@property (strong, nonatomic) IBOutlet UILabel *trackTitleLabel;
@property (strong, nonatomic) IBOutlet UILabel *artistNameLabel;
@property (strong, nonatomic) IBOutlet UIView *whatsPlayingView;
@property (strong, nonatomic) IBOutlet UIImageView *currentlyPlayingCoverart;
@property (strong, nonatomic) IBOutlet UILabel *currentlyPlayingArtistLabel;
@property (strong, nonatomic) IBOutlet UILabel *currentlyPlayingTrackTitleLabel;
@property (strong, nonatomic) IBOutlet UIView *currentlyPlayingParentView;
@property (strong, nonatomic) IBOutlet UIButton *thumbsUpButton;
@property (strong, nonatomic) IBOutlet UIButton *thumbsDownButton;

@property (strong, nonatomic) IBOutlet UILabel *currentlyPlayingInfoLabel;
@property (strong, nonatomic) IBOutlet UIView *mainPlayerView;

@property (strong, nonatomic) IBOutlet UIView *historyView;
@property (strong, nonatomic) IBOutlet UITableView *historyTableView;

- (IBAction)skipToNextItem:(id)sender;
- (IBAction)skipToPreviousItem:(id)sender;
- (IBAction)play:(id)sender;

- (IBAction)thumbsUpSelection:(id)sender;
- (IBAction)showListView:(id)sender;

@end
