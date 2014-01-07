//
//  GeofenceViewController.m
//  Clockator
//
//  Created by Sabrina Ren on 12/23/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//
#import "GeofenceViewController.h"
#import "AppDelegate.h"
#import "PlaceIconViewController.h"
#import "Geofence.h"
#import "Place.h"
#import "UIColor+customColours.h"
#import <CoreLocation/CoreLocation.h>

@interface GeofenceViewController ()
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *iconButton;
@property (weak, nonatomic) IBOutlet UISearchBar *placesSearchBar;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UITableView *resultsTableView;
@property (nonatomic) IBOutlet UITextField *nameField;

- (IBAction)chooseIcon:(id)sender;
- (IBAction)sliderChanged:(id)sender;

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

@property (nonatomic) CLPlacemark *placemark;
@property (nonatomic) MKLocalSearchResponse *searchResults;
@property CLLocationCoordinate2D coords;
@property NSInteger displayCurrent;
@property NSInteger iconIndex;
@property BOOL placeChanged;
@property double radius;
@end

@implementation GeofenceViewController
@synthesize clockPlaces, currentLocation, geoPlace;
@synthesize mapView, iconButton, placesSearchBar, resultsTableView, nameField;
@synthesize placemark, searchResults, coords;

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
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    self.managedObjectContext = appDelegate.managedObjectContext;
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(doneButtonActionHandler:)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
    resultsTableView.delegate = self;
    placesSearchBar.delegate = self;
    nameField.delegate = self;
    mapView.delegate = self;
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 10, 40)];
    [titleLabel setFont:[UIFont fontWithName:@"DistrictPro-Thin" size:25]];
    [titleLabel setTextColor:[UIColor whiteColor]];
    
    placesSearchBar.layer.borderWidth = 1;
    placesSearchBar.layer.borderColor = [[UIColor whiteColor] CGColor];
    
    if (geoPlace) {
        titleLabel.text = geoPlace.fenceName;
        nameField.text = geoPlace.fenceName;
        placesSearchBar.text = geoPlace.fenceAddress;
        placemark = geoPlace.fencePlacemark;
        self.radius = geoPlace.fenceRegion.radius;
        self.iconIndex = geoPlace.iconIndex;
        [self showMap];
    } else {
        titleLabel.text = @"New Place";
        self.radius = 100;
        self.iconIndex = 1;
    }
    [iconButton setImage:[clockPlaces[self.iconIndex] placeIcon] forState:UIControlStateNormal];
    self.navigationItem.titleView = titleLabel;
    [self.slider setValue:self.radius animated:YES];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    resultsTableView.hidden = YES;
    self.displayCurrent = YES;
    self.activityIndicator.hidesWhenStopped = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    NSLog(@"View appeared");
}

#pragma mark - UI Behaviour

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
    [placesSearchBar resignFirstResponder];
    
    resultsTableView.hidden = YES;
    
    [super touchesBegan:touches withEvent:event];
}

- (IBAction)chooseIcon:(id)sender {
    PlaceIconViewController *iconController = (PlaceIconViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"PlaceIconViewController"];
    iconController.delegate = self;
    iconController.clockPlaces = self.clockPlaces;
    iconController.isIconView = YES;
    iconController.currentIconIndex = self.iconIndex;
    [self.navigationController pushViewController:iconController animated:YES];
}

- (IBAction)sliderChanged:(id)sender {
    UISlider *slider = (UISlider *)sender;
    double value = slider.value;
    self.radius = value;
    [self showCircle];
}

- (void)showAlertWithTitle:(NSString *)title fieldTag:(NSInteger)tag {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    alert.tag = tag;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 0) [placesSearchBar becomeFirstResponder];
    else if (alertView.tag == 1) [nameField becomeFirstResponder];
}

- (void)doneButtonActionHandler:(id)sender {
    NSString *iden = [NSString stringWithFormat:@"%i%@", self.iconIndex, nameField.text];
    CLCircularRegion *region = [[CLCircularRegion alloc] initWithCenter:coords radius:self.radius identifier:iden];
    if (placemark) {
        BOOL isNew = YES;
        if (geoPlace) isNew = NO;
        else geoPlace = [NSEntityDescription insertNewObjectForEntityForName:@"Geofence" inManagedObjectContext:self.managedObjectContext];
        
        geoPlace.fenceRegion = region;
        geoPlace.fencePlacemark = placemark;
        geoPlace.iconIndex = self.iconIndex;
        
        if (nameField.text.length > 0) {
            geoPlace.fenceName = nameField.text;

            [self.delegate geofenceViewController:self didUpdateGeofence:geoPlace isNew:isNew];
            [self.navigationController popViewControllerAnimated:YES];
        }
        else [self showAlertWithTitle:@"Enter a name" fieldTag:1];
    }
    else if (nameField.text.length > 0) [self showAlertWithTitle:@"Search for an address" fieldTag:0];
    else [self.navigationController popViewControllerAnimated:YES];
}

- (void)backButtonActionHandler {
    NSLog(@"back button");
}

#pragma mark - Search methods

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    
    [self localSearch:searchBar.text showAlert:YES];
    
    self.placeChanged = YES;
}

- (void)localSearch:(NSString *)query showAlert:(BOOL)showAlert {
    [self.activityIndicator startAnimating];
    MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];
    request.naturalLanguageQuery = query;
    request.region = self.mapView.region;

    // Search a city-sized area
    if (mapView.region.span.latitudeDelta < 1) {
        request.region = MKCoordinateRegionMakeWithDistance(mapView.region.center, 1, 1);
    }
    
    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];
    
    [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
        [self.activityIndicator stopAnimating];
        if (!self.displayCurrent) {
            searchResults = response;
            
            [resultsTableView reloadData];
            NSLog(@"num results %i", response.mapItems.count);
            
            MKMapItem *item = [response.mapItems firstObject];
            placemark = item.placemark;
            
            if (placemark && showAlert) {
                [self showMap];
                resultsTableView.hidden = YES;
            }
            else if (showAlert) {
                [self showAlertWithTitle:@"No location found" fieldTag:0];
            }
        }
    }];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    
    if (searchText.length > 0) {
        NSLog(@"Text changed");
        self.displayCurrent = NO;
        resultsTableView.hidden = NO;
        [self localSearch:searchText showAlert:NO];
    }
    else {
        NSLog(@"No text in bar");
        self.displayCurrent = YES;
        searchResults = nil;
        resultsTableView.hidden = NO;
        [resultsTableView reloadData];
        
        [searchBar becomeFirstResponder];
        
        placemark = nil;
        [mapView removeAnnotations:mapView.annotations];
        [mapView removeOverlays:mapView.overlays];
    }

}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    resultsTableView.hidden = NO;
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
    [placesSearchBar resignFirstResponder];
    resultsTableView.hidden = YES;
    return YES;
}

#pragma mark - Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSLog(@"Num rows: %i", searchResults.mapItems.count);
    if (self.displayCurrent) return searchResults.mapItems.count + 1;
    else return searchResults.mapItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Cell for row: %i displaysCurrent: %i", indexPath.row, self.displayCurrent);
    NSLog(@"Cell for row: Map items count: %i", searchResults.mapItems.count);

    UITableViewCell *cell;
    if (self.displayCurrent && indexPath.row == 0) {
        cell = [resultsTableView dequeueReusableCellWithIdentifier:@"ImageCell"];
        cell.textLabel.text = @"Current location";
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UIImageView *imgV = [[UIImageView alloc] initWithFrame:CGRectMake(12, 12, 22, 22)];
        imgV.backgroundColor = [UIColor clearColor];
        [imgV.layer setMasksToBounds:YES];
        [imgV setImage:[UIImage imageNamed:@"CurrentLocation.png"]];
        [cell.contentView addSubview:imgV];
        
        cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    else {
        cell = [resultsTableView dequeueReusableCellWithIdentifier:@"SubtitleCell"];
        if (indexPath.row < searchResults.mapItems.count) {
            MKMapItem *mapItem = searchResults.mapItems[indexPath.row];
            cell.textLabel.text = mapItem.name;
            
            NSString *address = mapItem.placemark.addressDictionary[@"Street"];
            if (address) {
                address = [NSString stringWithFormat:@"%@, %@", address, mapItem.placemark.addressDictionary[@"City"]];
            }
            cell.detailTextLabel.text = address;
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [placesSearchBar resignFirstResponder];
    NSLog(@"Did select: Map items count: %i", searchResults.mapItems.count);

    if (self.displayCurrent && indexPath.row==0) {
        if (currentLocation) {
        [placesSearchBar setText:@"Current location"];
        [self.activityIndicator startAnimating];
        CLGeocoder * geoCoder = [[CLGeocoder alloc] init];
        [geoCoder reverseGeocodeLocation:self.currentLocation completionHandler:^(NSArray *placemarks, NSError *error) {
            if (error) {
                NSLog(@"Geocoder error: %@", error.description);
            } else {
                [self.activityIndicator stopAnimating];
                NSLog(@"reverse geocoding");
                placemark = [placemarks firstObject];
                [placesSearchBar setText:placemark.name];
                [self showMap];
            }
        }];
        }
        else [self showAlertWithTitle:@"Could not find location" fieldTag:-1];
    }
    else {
        if (indexPath.row < searchResults.mapItems.count) {
            MKMapItem *mapItem = searchResults.mapItems[indexPath.row];
            NSLog(@"Selected map row %i", indexPath.row);
            placemark = mapItem.placemark;
            [self showMap];
        }
    }
    resultsTableView.hidden = YES;
}

#pragma mark - Text field methods

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

#pragma mark - Map rendering

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
    mapRegion.span.latitudeDelta = self.radius/20000;
    mapRegion.span.longitudeDelta = self.radius/20000;
    [mapView setRegion:mapRegion animated:YES];
}

- (void)showCircle {
    // Removes old circle and creates new circle
    [mapView removeOverlays:mapView.overlays];

    MKCircle *circle = [MKCircle circleWithCenterCoordinate:coords radius:self.radius];
    [mapView addOverlay:circle];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    MKCircleRenderer *renderer = [[MKCircleRenderer alloc] initWithCircle:overlay];
    renderer.fillColor = [UIColor customTransparentMapSalmon];
    return renderer;
}

#pragma mark - ClockPlacesSettingsController protocol method

- (void)placeIconController:(PlaceIconViewController *)controller didChangeIconIndex:(NSInteger)index {
    NSLog(@"Index: %i", index);
    self.iconIndex = index;
    [iconButton setImage:[clockPlaces[self.iconIndex] placeIcon] forState:UIControlStateNormal];
}

- (void)didChangeClockFace {
    // For use with settings controller
}

@end




