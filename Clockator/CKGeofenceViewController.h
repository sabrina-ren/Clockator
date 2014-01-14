//
//  GeofenceViewController.h
//  Clockator
//
//  Created by Sabrina Ren on 12/23/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import "CKPlaceIconViewController.h"
#import <MapKit/MapKit.h>
#import <UIKit/UIKit.h>

@class CKGeofenceViewController;
@class CKGeofence;

@protocol CKGeofenceControllerDelegate <NSObject>
- (void)geofenceViewController:(CKGeofenceViewController *)controller didUpdateGeofence:(CKGeofence *)geofence isNew:(BOOL)isNew;
@end

@interface CKGeofenceViewController : UIViewController <MKMapViewDelegate,UIAlertViewDelegate, UISearchBarDelegate, UITableViewDelegate, UITextFieldDelegate,  CKPlaceIconControllerDelegate>

@property (nonatomic) NSMutableArray *clockPlaces;
@property (nonatomic) CLLocation *currentLocation;
@property (nonatomic) CKGeofence *geoPlace;
@property BOOL isReachable;

@property (nonatomic, weak) id <CKGeofenceControllerDelegate> delegate;

@end
