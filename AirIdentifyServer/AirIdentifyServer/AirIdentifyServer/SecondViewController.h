//
//  SecondViewController.h
//  AirIdentifyServer
//
//  Created by Kshitij Deshpande on 7/29/13.
//  Copyright (c) 2013 Gracenote. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"


@interface SecondViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate>

@property (strong, nonatomic) IBOutlet UIPickerView *serviceTypePicker;
@property (strong, nonatomic) IBOutlet UIPickerView *specificServiceTypePicker;
@property (strong, nonatomic) IBOutlet UIView *segmentedControlView;
@property (strong, nonatomic) IBOutlet UIView *resetSegmentedControlView;
@property (strong, nonatomic) IBOutlet UILabel *connectionStatusLabel;
@end
