//
//  ClockViewController.h
//  Clockator
//
//  Created by Sabrina Ren on 11/22/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import "SettingsViewController.h"
#import <Parse/Parse.h>
#import <UIKit/UIKit.h>

@class ClockViewController;

@interface ClockViewController : UIViewController <CLLocationManagerDelegate, SettingsControllerDelegate>

@end
