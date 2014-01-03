//
//  ClockViewController.h
//  Clockator
//
//  Created by Sabrina Ren on 11/22/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import "LoginViewController.h"
#import "SettingsViewController.h"
#import <Parse/Parse.h>
#import "PopoverView.h"
#import <UIKit/UIKit.h>

@class ClockViewController;

@interface ClockViewController : UIViewController <CLLocationManagerDelegate, NSURLConnectionDelegate, SettingsControllerDelegate>

@property (nonatomic) NSMutableArray *friendIds;

@end
