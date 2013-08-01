//
//  FirstViewController.h
//  AirIdentifyServer
//
//  Created by Kshitij Deshpande on 7/29/13.
//  Copyright (c) 2013 Gracenote. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FirstViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIView *volumeView;
@property (strong, nonatomic) IBOutlet UIButton *playButton;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UIView *volumeBarView;
@property (strong, nonatomic) IBOutlet UILabel *trackTitleLabel;
@property (strong, nonatomic) IBOutlet UILabel *artistNameLabel;


- (IBAction)skipToNextItem:(id)sender;
- (IBAction)skipToPreviousItem:(id)sender;
- (IBAction)play:(id)sender;


@end
