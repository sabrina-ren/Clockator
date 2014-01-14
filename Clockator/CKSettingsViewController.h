//
//  SettingsViewController.h
//  Clockator
//
//  Created by Sabrina Ren on 12/23/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import "CKGeofenceViewController.h"
#import <UIKit/UIKit.h>

@class CKSettingsViewController;
@class CKGeofence;

typedef enum {
    newPlace,
    deletedPlace,
    changedPlace
} ChangeType;

@protocol CKSettingsControllerDelegate <NSObject>
- (void)didUpdateGeofence:(CKGeofence *)geofence changeType:(ChangeType)type;
- (void)didChangeClockFace;
@end

@interface CKSettingsViewController : UITableViewController <CKGeofenceControllerDelegate, CKPlaceIconControllerDelegate>

@property (nonatomic) NSArray *friendIds;
@property (nonatomic) CLLocation *currentLocation;
@property (nonatomic) NSMutableArray *clockPlaces;
@property (nonatomic) NSMutableArray *geofences;
@property BOOL isReachable;

@property (nonatomic, weak) id <CKSettingsControllerDelegate> delegate;

- (void)didUpdateCurrentLocation:(CLLocation *)newLocation;

@end
