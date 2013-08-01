//
//  SecondViewController.m
//  AirIdentifyServer
//
//  Created by Kshitij Deshpande on 7/29/13.
//  Copyright (c) 2013 Gracenote. All rights reserved.
//

#import "SecondViewController.h"
#import "AppDelegate.h"

@interface SecondViewController ()
@property (strong) MCPeerID *peerID;
@property (strong) MCNearbyServiceAdvertiser* advertiser;
@property (strong) MCSession *session;

@property (strong) UISegmentedControl *seg;
@property (strong) UISegmentedControl *resetseg;

@end

@implementation SecondViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.seg = [[UISegmentedControl alloc] initWithItems:@[@"Broadcast Service"]];
    self.seg.momentary = YES;
    self.seg.tintColor = [UIColor whiteColor];
    self.seg.backgroundColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:0.8];
    
    CGRect rect=self.segmentedControlView.bounds;
    rect.size.height=rect.size.height/2;
    
    self.seg.frame =rect;
    self.seg.opaque = NO;
    [self.segmentedControlView addSubview:self.seg];
    
    [self.seg.layer setCornerRadius:5.0];
    [self.seg setClipsToBounds:YES];
    
    self.seg.enabled = NO;
    
    self.resetseg = [[UISegmentedControl alloc] initWithItems:@[@"Stop Services"]];
    self.resetseg.momentary = YES;
    self.resetseg.tintColor = [UIColor whiteColor];
    self.resetseg.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.8];
    
    rect=self.segmentedControlView.bounds;
    rect.size.height=rect.size.height/2;
    
    self.resetseg.frame =rect;
    self.resetseg.opaque = NO;
    [self.resetSegmentedControlView addSubview:self.resetseg];
    
    [self.resetseg.layer setCornerRadius:5.0];
    [self.resetseg setClipsToBounds:YES];
    
    
    [self.seg addTarget:self action:@selector(broadcastService:) forControlEvents:UIControlEventValueChanged];
    
    [self.resetseg addTarget:self action:@selector(stopServices:) forControlEvents:UIControlEventValueChanged];
    
    
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - PickerView Data Source Methods

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if(pickerView==self.serviceTypePicker)
       return 6;
    
    return 3;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}


#pragma mark - PickerView Delegate Methods

- (NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if(pickerView==self.serviceTypePicker)
    {
        switch (row)
        {
            case 0:
                return [[NSAttributedString alloc] initWithString:@"Cardio" attributes:nil];
                break;
            case 1:
                return [[NSAttributedString alloc] initWithString:@"Weights" attributes:nil];
                break;
            case 2:
                return [[NSAttributedString alloc] initWithString:@"Training" attributes:nil];
                break;
            case 3:
                return [[NSAttributedString alloc] initWithString:@"Yoga" attributes:nil];
                break;
            case 4:
                return [[NSAttributedString alloc] initWithString:@"Cross Training" attributes:nil];
                break;
            case 5:
                return [[NSAttributedString alloc] initWithString:@"Cycling" attributes:nil];
                break;
                
        }
    }
    else
    {
        
        switch (row)
        {
            case 0:
                return [[NSAttributedString alloc] initWithString:@"Sedentery/Spot" attributes:nil];
                break;
            case 1:
                return [[NSAttributedString alloc] initWithString:@"Walking" attributes:nil];
                break;
            case 2:
                return [[NSAttributedString alloc] initWithString:@"Runnning" attributes:nil];
                break;
        }
        
    }
    
    return [[NSAttributedString alloc] initWithString:@"NULL" attributes:nil];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSLog(@"didSelect Row");
    self.seg.enabled = YES;
}

-(void) stopServices:(id) sender
{
     AppDelegate *appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    
    [appDelegate.peripheralManager stopAdvertising];
    [appDelegate.peripheralManager removeAllServices];
    
    [self.advertiser stopAdvertisingPeer];
    NSURLRequest
}

-(void) broadcastService:(id) sender
{
    NSUInteger major = CARDIO_BEACON_TYPE+[self.serviceTypePicker selectedRowInComponent:0];
    NSUInteger minor = SITTING_BEACON_TYPE+[self.specificServiceTypePicker selectedRowInComponent:0];
    
    NSString *serviceTypeFromSelectionStr = [self serviceTypeFromSelection];
    
    AppDelegate *appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    
    appDelegate.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:appDelegate queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    
    [appDelegate.peripheralManager stopAdvertising];
    [appDelegate.peripheralManager removeAllServices];
    
    CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString: AIRIDENTIFY_UUID] major:major minor:minor identifier:serviceTypeFromSelectionStr];
    
    NSDictionary *peripheralData = [region peripheralDataWithMeasuredPower:@-59];
    
    [((AppDelegate*)[UIApplication sharedApplication].delegate).peripheralManager startAdvertising:peripheralData];
    
    
    if(self.advertiser)
    {
        [self.advertiser stopAdvertisingPeer];
        self.advertiser = nil;
    }
    
    
    self.peerID = [[MCPeerID alloc] initWithDisplayName:serviceTypeFromSelectionStr];
    
    self.advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.peerID discoveryInfo:@{@"Advertiser-name":self.peerID.displayName} serviceType:serviceTypeFromSelectionStr];
    
    [self.advertiser stopAdvertisingPeer];
    
    self.advertiser.delegate = appDelegate;
    
    self.session = [[MCSession alloc] initWithPeer:self.peerID securityIdentity:nil encryptionPreference:MCEncryptionOptional];
    
    appDelegate.peerID = self.peerID;
    appDelegate.mcsession = self.session;
    
    self.session.delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    
    [self.advertiser startAdvertisingPeer];
    
    self.connectionStatusLabel.alpha = 1.0;
    self.connectionStatusLabel.text = @"Services Broadcasted Successfully!";
    
    [UIView animateWithDuration:5.5 animations:^{
        
        self.connectionStatusLabel.alpha = 0.0;
    
    }];
    
    self.seg.enabled = NO;
    
}


-(NSString*) serviceTypeFromSelection
{
    NSString *peerDisplayName = nil;
    NSString *specificServiceType = nil;
    
    switch (CARDIO_BEACON_TYPE+[self.serviceTypePicker selectedRowInComponent:0])
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
            peerDisplayName = @"Cycling";;
            break;
            default:
               peerDisplayName = @"Cardio";
            break;
            
    }
    
    
    switch (SITTING_BEACON_TYPE+[self.specificServiceTypePicker selectedRowInComponent:0])
    {
        case SITTING_BEACON_TYPE:
            specificServiceType = @"Sedentary";
            break;
        case WALKING_BEACON_TYPE:
            specificServiceType = @"Walking";
            break;
        case RUNNING_BEACON_TYPE:
            specificServiceType = @"Runnning";
            break;
        default:
             specificServiceType = @"Runnning";
            break;
    }
    
    NSString *combinedString = [NSString stringWithFormat:@"%@%@",[peerDisplayName substringToIndex:4], [specificServiceType substringToIndex:4]];
    
    NSString *truncatedString = [combinedString substringToIndex:7];
    
    return [NSString stringWithFormat:@"airid-%@", truncatedString ];
}


@end
