//
//  ClockViewController.h
//  Clockator
//
//  Created by Sabrina Ren on 11/22/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <sqlite3.h>
#import "Location.h"
#import "Friend.h"
#import "AppDelegate.h"

@interface ClockViewController : UIViewController <CLLocationManagerDelegate>

@property (nonatomic, copy) NSMutableArray *locations;
@property (nonatomic, copy) NSMutableArray *friends;
@property (nonatomic, copy) NSMutableArray *friendsAtLocation;
@property (nonatomic, retain) NSMutableArray *hands;

@end
