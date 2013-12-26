//
//  MyPlacesViewController.h
//  Clockator
//
//  Created by Sabrina Ren on 12/23/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <AddressBook/AddressBook.h>
#import <MapKit/MapKit.h>
#import "geofencedPlace.h"

@class MyPlacesViewController;

@protocol MyPlacesViewControllerDelegate <NSObject>
- (void)myPlacesViewController:(MyPlacesViewController *)controller didUpdateGeofence:(geofencedPlace *)geofence isNew:(BOOL)isNew;
@end

@interface MyPlacesViewController : UIViewController <UITextFieldDelegate, MKMapViewDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) IBOutlet UITextField *addressField;
@property (strong, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
- (IBAction)sliderChanged:(id)sender;

@property (nonatomic) geofencedPlace *geoPlace;
@property (nonatomic, weak) id <MyPlacesViewControllerDelegate> delegate;

@end
