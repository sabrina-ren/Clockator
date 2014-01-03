//
//  SettingsViewController.h
//  Clockator
//
//  Created by Sabrina Ren on 12/23/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import "GeofenceViewController.h"
#import <UIKit/UIKit.h>

@class SettingsViewController;
@class Geofence;

typedef enum {
    newPlace,
    deletedPlace,
    changedPlace
} ChangeType;

@protocol SettingsControllerDelegate <NSObject>
- (void)didUpdateGeofence:(Geofence *)geofence changeType:(ChangeType)type;
@end

@interface SettingsViewController : UITableViewController <GeofenceControllerDelegate>

@property (nonatomic) NSArray *friendIds;
@property (nonatomic) CLLocation *currentLocation;
@property (nonatomic) NSMutableArray *clockPlaces;
@property (nonatomic) NSMutableArray *geofences;

@property (nonatomic, weak) id <SettingsControllerDelegate> delegate;

- (void)didUpdateCurrentLocation:(CLLocation *)newLocation;

@end
