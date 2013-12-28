//
//  MyPlacesViewController.m
//  Clockator
//
//  Created by Sabrina Ren on 12/23/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import "MyPlacesViewController.h"
#import "IconViewController.h"
#import "Place.h"
#import "UIColor+customColours.h"
#import <AddressBookUI/AddressBookUI.h>

@interface MyPlacesViewController ()

@property (nonatomic) MKLocalSearchResponse *searchResults;
@property (nonatomic) CLPlacemark *placemark;
@property CLLocationCoordinate2D coords;
@property double radius;
@property BOOL placeChanged;
@property NSInteger displayCurrent;

@end

@implementation MyPlacesViewController
@synthesize geoPlace, radius, coords, placemark, searchResults;
@synthesize nameField, mapView, iconButton, placesSearchBar, resultsTableView;

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
    
    resultsTableView.delegate = self;
    placesSearchBar.delegate = self;
    nameField.delegate = self;
    mapView.delegate = self;

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 10, 40)];
    [titleLabel setTextColor:[UIColor whiteColor]];
    
    if (geoPlace) {
        titleLabel.text = geoPlace.fenceName;
        nameField.text = geoPlace.fenceName;
        placesSearchBar.text = geoPlace.fenceAddress;
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
 
    resultsTableView.hidden = YES;
    self.displayCurrent = YES;
    self.activityIndicator.hidesWhenStopped = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [placesSearchBar becomeFirstResponder];
}

- (void)doneButtonActionHandler:(id)sender {

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
    //    request.region = MKCoordinateRegionForMapRect(MKMapRectWorld);
    
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
            cell.detailTextLabel.text = mapItem.placemark.addressDictionary[@"Street"];
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [placesSearchBar resignFirstResponder];
    NSLog(@"Did select: Map items count: %i", searchResults.mapItems.count);

    if (self.displayCurrent && indexPath.row==0) {
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

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
    [placesSearchBar resignFirstResponder];
    
    resultsTableView.hidden = YES;
    
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

- (IBAction)chooseIcon:(id)sender {
    IconViewController *iconController = (IconViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"IconViewController"];
    [self.navigationController pushViewController:iconController animated:YES];
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
    if (alertView.tag == 0) [placesSearchBar becomeFirstResponder];
    else [nameField becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end




