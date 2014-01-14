//
//  CKClockViewController.h
//  Clockator
//
//  Created by Sabrina Ren on 11/22/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import "CKLoginViewController.h"
#import "CKSettingsViewController.h"
#import <Parse/Parse.h>
#import "PopoverView.h"
#import <UIKit/UIKit.h>

@class CKClockViewController;

@interface CKClockViewController : UIViewController <CLLocationManagerDelegate, NSURLConnectionDelegate, CKSettingsControllerDelegate>

@property (nonatomic) NSMutableArray *friendIds;
@property BOOL isReachable;
@property BOOL shouldRefreshClock;

@end
