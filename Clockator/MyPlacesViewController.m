//
//  MyPlacesViewController.m
//  Clockator
//
//  Created by Sabrina Ren on 12/23/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import "MyPlacesViewController.h"
#import "Place.h"
#import "UIColor+customColours.h"

@interface MyPlacesViewController ()

@property CLLocationCoordinate2D coords;
@property (nonatomic) CLPlacemark *placemark;
@property double radius;
@property BOOL placeChanged;

@end

@implementation MyPlacesViewController
@synthesize geoPlace, radius, coords, placemark;
@synthesize addressField, nameField, mapView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonActionHandler:)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
    addressField.delegate = self;
    nameField.delegate = self;
    mapView.delegate = self;

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 10, 40)];
    [titleLabel setTextColor:[UIColor whiteColor]];
    
    if (geoPlace) {
        titleLabel.text = geoPlace.fenceName;
        nameField.text = geoPlace.fenceName;
        addressField.text = geoPlace.fenceAddress;
        placemark = geoPlace.fencePlacemark;
        radius = geoPlace.fenceRegion.radius;
        [self showMap];
    } else {
        titleLabel.text = @"New Place";
        radius = 100;
    }

    self.navigationItem.titleView = titleLabel;
    [self.slider setValue:radius animated:YES];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void) doneButtonActionHandler:(id)sender {

    CLCircularRegion *region = [[CLCircularRegion alloc] initWithCenter:coords radius:radius identifier:nameField.text];
    if (placemark) {
        BOOL isNew = TRUE;
        if (geoPlace) isNew = NO;
        else geoPlace = [[geofencedPlace alloc] init];
        
        geoPlace.fenceRegion = region;
        geoPlace.fencePlacemark = placemark;
        
        if (nameField.text.length > 0) {
            geoPlace.fenceName = nameField.text;
            [self.delegate myPlacesViewController:self didUpdateGeofence:geoPlace isNew:isNew];
            [self.navigationController popViewControllerAnimated:YES];
        }
        else [self showAlertWithTitle:@"Enter a name" fieldTag:1];
    }
    else if (nameField.text.length > 0) [self showAlertWithTitle:@"Search for an address" fieldTag:0];
    else [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    if (textField.tag == 0) {
        MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];
        request.naturalLanguageQuery = textField.text;
        request.region = self.mapView.region;
        
        MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];
        [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
            MKMapItem *item = [response.mapItems firstObject];
            placemark = item.placemark;

            if (placemark)[self showMap];
            else {
                [self showAlertWithTitle:@"Couldn't find location" fieldTag:0];
            }
        }];
        
        self.placeChanged = YES;

//        CLGeocoder *geocoder = [[CLGeocoder alloc] init];
//        NSString *addressString = addressField.text;
//        [geocoder geocodeAddressString:addressString completionHandler:^(NSArray *placemarks, NSError *error)
//        {
//            if (error) {
//                NSLog(@"Geocode failed with error: %@", error);
//                return;
//            }
//            if (placemarks && placemarks.count > 0) {
//                placemark = placemarks[0];
//                CLLocation *location = placemark.location;
//                coords = location.coordinate;
//                [self showMap];
//            }
//        }];
    }
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    if (textField.tag == 0) {
        placemark = nil;
        [mapView removeAnnotations:mapView.annotations];
        [mapView removeOverlays:mapView.overlays];
    }
    return YES;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
    [super touchesBegan:touches withEvent:event];
}

- (void)showMap {
    [mapView removeAnnotations:mapView.annotations];
    
    // Save variables
    coords = placemark.location.coordinate;
    NSLog(@"Coordinates: %f, %f", coords.latitude, coords.longitude);
    NSLog(@"Placemark name: %@", placemark.name);
    
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    annotation.coordinate = coords;
    annotation.title = placemark.name;
    [mapView addAnnotation:annotation];
    
    [self showCircle];
    
    MKCoordinateRegion mapRegion;
    mapRegion.center = coords;
    mapRegion.span.latitudeDelta = radius/20000;
    mapRegion.span.longitudeDelta = radius/20000;
    [mapView setRegion:mapRegion animated:YES];
}

- (void)showCircle {
    // Removes old circle and creates new circle
    [mapView removeOverlays:mapView.overlays];

    MKCircle *circle = [MKCircle circleWithCenterCoordinate:coords radius:radius];
    [mapView addOverlay:circle];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    MKCircleRenderer *renderer = [[MKCircleRenderer alloc] initWithCircle:overlay];
    renderer.fillColor = [UIColor customTransparentTurquoise];
    return renderer;
}

- (IBAction)sliderChanged:(id)sender {
    UISlider *slider = (UISlider *)sender;
    double value = slider.value;
    radius = value;
    [self showCircle];
}

- (void)showAlertWithTitle:(NSString *)title fieldTag:(NSInteger)tag {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    alert.tag = tag;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 0) [addressField becomeFirstResponder];
    else [nameField becomeFirstResponder];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end




