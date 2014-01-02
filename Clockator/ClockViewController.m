//
//  ClockViewController.m
//  Clockator
//
//  Created by Sabrina Ren on 11/22/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import "ClockViewController.h"
#import "FBFindFriendsController.h"
#import "LoginViewController.h"
#import "SettingsViewController.h"
#import "GeofencePlace.h"
#import "Place.h"

@interface ClockViewController ()
@property (nonatomic) NSMutableArray *clockPlaces;
@property (nonatomic) NSMutableArray *iconViews;
@property (nonatomic) NSMutableArray *myGeofences;
@property (nonatomic, retain) NSMutableArray *hands;
@property (nonatomic) SettingsViewController *settingsController;

@property (nonatomic) CLLocation *currentLocation;
@property (nonatomic) CLLocationManager *locationManager;
@property BOOL didStartMonitoringRegion;
@property BOOL withinGeofences;
@end

@implementation ClockViewController
@synthesize clockPlaces, iconViews, myGeofences, hands, settingsController;
@synthesize friendIds;
@synthesize currentLocation, locationManager;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Appearance setup
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 10, 40)];
    [titleLabel setFont:[UIFont fontWithName:@"ChannelSlanted1" size:20]];
    [titleLabel setTextColor:[UIColor whiteColor]];
    [titleLabel setText:@"Clockator"];
    self.navigationItem.titleView = titleLabel;
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStylePlain target:self action:@selector(addFriendsTouchHandler:)];
    self.navigationItem.rightBarButtonItem = addButton;
    
    // Get default clock places
    clockPlaces = [Place getDefaultPlaces];

    [self loadShownClockPlaces];
    
    NSLog(@"finished loading");
//    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
//        [FBSession sessionOpen];
    FBCacheDescriptor *cacheDescriptor = [FBFindFriendsController cacheDescriptor];
    [cacheDescriptor prefetchAndCacheForSession:FBSession.activeSession];
//    }
    
    myGeofences = [[NSMutableArray alloc] init];
    
    // Location Manager
    locationManager = [[CLLocationManager alloc] init];
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.delegate = self;
    [locationManager startUpdatingLocation];
    currentLocation = locationManager.location;
    
    // Clear monitored locations
    for (CLRegion *oldRegion in locationManager.monitoredRegions) {
        [locationManager stopMonitoringForRegion:oldRegion];
    }
    
    [self monitorRegions];
    
//    PFQuery *query = [PFUser query];
//    [query whereKey:@"displayName" equalTo:@"Sandra Amgdbgfgabbi Smithberg"];
//    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
//        PFUser *user = [objects firstObject];
//        NSLog(@"Object count at clock: %i", objects.count);
//        NSArray *array = [NSArray arrayWithObjects:user.objectId, nil];
//        PFUser *current = [PFUser currentUser];
//        
//        [current setObject:array forKey:@"friends"];
//    }];
    
    
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBar.translucent = NO;
    
    // Remove old place icons
    for (UIImageView *imgV in iconViews) {
        [imgV removeFromSuperview];
    }
    [self loadShownClockPlaces];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI Behaviour

- (void)loadShownClockPlaces {
    iconViews = [NSMutableArray arrayWithCapacity:clockPlaces.count];
    hands = [[NSMutableArray alloc] init];
    
    NSInteger numShownPlaces = 0;
    for (Place *thisPlace in clockPlaces) {
        if (thisPlace.isShown) numShownPlaces++;
    }
    double angle = 2*M_PI/numShownPlaces;
    
    int angleIndex = 0; // Tracks index of shown places not all clock places
    
    for (int i=0; i<clockPlaces.count; i++) {
        if (![clockPlaces[i] isShown]) continue;
        CGFloat locRadius = 140;
        CGFloat x = 140 + locRadius*cos(angle*angleIndex + M_PI/2);
        CGFloat y = 200 - locRadius*sin(angle*angleIndex + M_PI/2);
        
        UIView *placeV = [[UIView alloc] initWithFrame:CGRectMake(x,y,2,40)];
        UIImageView *imgV = [[UIImageView alloc] initWithImage:[clockPlaces[i] placeIcon]];
        [imgV setFrame:CGRectMake(0, 0, 40, 30)];
        [placeV addSubview:imgV];
        [[self view] addSubview:placeV];
        [iconViews addObject:placeV];
        angleIndex++;
    }
}

- (IBAction)addFriendsTouchHandler:(id)sender {
    settingsController = [self.storyboard instantiateViewControllerWithIdentifier:@"SettingsViewController"];
    settingsController.clockPlaces = clockPlaces;
    settingsController.myGeofences = myGeofences;
    settingsController.currentLocation = locationManager.location;
    settingsController.friendIds = friendIds;
    settingsController.delegate = self;
    [self.navigationController pushViewController:settingsController animated:YES];
}

#pragma mark - Location manager methods

- (void)monitorRegions {
    for (GeofencePlace *place in myGeofences) {
        [locationManager startMonitoringForRegion:place.fenceRegion];
    }
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    NSLog(@"Now monitoring %@", region.identifier);
}

- (IBAction)updateLocation:(id)sender {
    NSString *coordinates = [NSString stringWithFormat:@"%f, %f", locationManager.location.coordinate.latitude, locationManager.location.coordinate.longitude];
    self.withinGeofences = NO;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:coordinates message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
    
    NSLog(@"Num monitored regions: %i", locationManager.monitoredRegions.count);
    for (GeofencePlace *place in myGeofences) {
        [locationManager requestStateForRegion:place.fenceRegion];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if ([currentLocation distanceFromLocation:locationManager.location] > 10) {
        // Register location change if greater than 10m
        NSLog(@"Location changed");
        currentLocation = locationManager.location;
        [settingsController didUpdateCurrentLocation:currentLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    NSLog(@"Location manager determined state");
    
    if (state == CLRegionStateInside) {
        NSLog(@"Is inside %@", region.identifier);
        self.withinGeofences = YES;
        [self shareLocation:[region.identifier substringFromIndex:1] iconIndex:[region.identifier substringToIndex:1]];
    }
    else if (state == CLRegionStateOutside) {
        NSLog(@"Is outside region %@", region.identifier);
        
        CLCircularRegion *lastRegion = [[myGeofences lastObject] fenceRegion];
        if ([region isEqual:lastRegion] && self.withinGeofences == NO) {
            NSLog(@"Is outside all geofences");
            [self shareLocation:@"Other" iconIndex:@"2"];
        }
    }
    else if (state == CLRegionStateUnknown) {
        NSLog(@"State unknown");
        // No update to database since previous location will be shared
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Location mgr failed: %@", error);
    // No update to database since previous location will be shared
}

#pragma mark - Parse database

- (void)shareLocation:(NSString *)name iconIndex:(NSString *)index {
    [[PFUser currentUser] setObject:name forKey:@"location"];
    [[PFUser currentUser] setObject:index forKey:@"iconIndex"];
    [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) NSLog(@"Save succeeded");
    }];
}

#pragma mark - SetingsViewController protocol method

- (void)didUpdateGeofence:(GeofencePlace *)geofence changeType:(ChangeType)type {
    if (type == deletedPlace || type == changedPlace) {
        [locationManager stopMonitoringForRegion:geofence.fenceRegion];
    }
    if (type == newPlace || type == changedPlace) {
        [locationManager startMonitoringForRegion:geofence.fenceRegion];
    }
    NSLog(@"Did update num monitored regions: %i", locationManager.monitoredRegions.count);
}

@end


