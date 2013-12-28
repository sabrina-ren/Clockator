//
//  SettingsViewController.h
//  Clockator
//
//  Created by Sabrina Ren on 12/23/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MyPlacesViewController.h"

//@protocol SettingsDelegate <NSObject>
//- (void)updateMyPlaces:(NSMutableArray *)places;
//@end

@interface SettingsViewController : UITableViewController <MyPlacesViewControllerDelegate>

@property (nonatomic) NSMutableArray *clockPlaces;
@property (nonatomic) NSMutableArray *myGeofences;
@property (nonatomic) CLLocation *currentLocation;

@end
