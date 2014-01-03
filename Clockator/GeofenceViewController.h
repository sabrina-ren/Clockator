//
//  GeofenceViewController.h
//  Clockator
//
//  Created by Sabrina Ren on 12/23/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import "PlaceIconViewController.h"
#import <MapKit/MapKit.h>
#import <UIKit/UIKit.h>

@class GeofenceViewController;
@class Geofence;

@protocol GeofenceControllerDelegate <NSObject>
- (void)geofenceViewController:(GeofenceViewController *)controller didUpdateGeofence:(Geofence *)geofence isNew:(BOOL)isNew;
@end

@interface GeofenceViewController : UIViewController <MKMapViewDelegate,UIAlertViewDelegate, UISearchBarDelegate, UITableViewDelegate, UITextFieldDelegate,  PlaceIconControllerDelegate>

@property (nonatomic) NSMutableArray *clockPlaces;
@property (nonatomic) CLLocation *currentLocation;
@property (nonatomic) Geofence *geoPlace;
@property (nonatomic, weak) id <GeofenceControllerDelegate> delegate;

@end
