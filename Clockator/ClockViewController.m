//
//  ViewController.m
//  Clockator
//
//  Created by Sabrina Ren on 11/22/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import "ClockViewController.h"
#import "FBFindFriendsController.h"
#import "SettingsViewController.h"
#import "Place.h"
#import "geofencedPlace.h"

@interface ClockViewController ()

@property (nonatomic) NSMutableArray *clockPlaces;
@property (nonatomic) NSMutableArray *myGeofences;
@property (nonatomic) NSMutableArray *placeViews;

@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) CLLocation *currentLocation;
@property (nonatomic) NSMutableArray *geofences;
@property BOOL didStartMonitoringRegion;
@property BOOL withinGeofences;

@end

@implementation ClockViewController
@synthesize locations, friends, friendsAtLocation, hands, placeViews;
@synthesize clockPlaces, myGeofences, locationManager, currentLocation;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Appearance setup
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 10, 40)];
    [titleLabel setFont:[UIFont fontWithName:@"ChannelSlanted1" size:20]];
    [titleLabel setTextColor:[UIColor whiteColor]];
    [titleLabel setText:@"Clockator"];
    self.navigationItem.titleView = titleLabel;
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonSystemItemAdd target:self action:@selector(addFriendsTouchHandler:)];
    self.navigationItem.rightBarButtonItem = addButton;
    
    // Get default clock places
    clockPlaces = [Place getDefaultPlaces];

    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

    
    // Temp hardcoded data for demo
    friends = appDelegate.friends;
    locations = appDelegate.locations;
    friendsAtLocation = appDelegate.friendsAtLocation;
    
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
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [locationManager startUpdatingLocation];
    currentLocation = locationManager.location;
    [self monitorRegions];

    self.geofences = [NSMutableArray arrayWithArray:[[self.locationManager monitoredRegions] allObjects]];
}

- (void)viewWillAppear:(BOOL)animated {
    // Remove old place icons
    for (UIImageView *imgV in placeViews) {
        [imgV removeFromSuperview];
    }
    [self loadShownClockPlaces];
    [self monitorRegions];
}

- (void)loadShownClockPlaces {
    placeViews = [NSMutableArray arrayWithCapacity:clockPlaces.count];
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
        [placeViews addObject:placeV];
        angleIndex++;
    }
}

- (IBAction)addFriendsTouchHandler:(id)sender {
    SettingsViewController *settingsController = [self.storyboard instantiateViewControllerWithIdentifier:@"SettingsViewController"];
    settingsController.clockPlaces = clockPlaces;
    settingsController.myGeofences = myGeofences;
    settingsController.currentLocation = currentLocation;
    [self.navigationController pushViewController:settingsController animated:YES];
}

- (void)monitorRegions {
    for (geofencedPlace *place in myGeofences) {
        [locationManager startMonitoringForRegion:place.fenceRegion];
    }
}

- (IBAction)updateLocation:(id)sender {
    NSLog(@"%f, %f", currentLocation.coordinate.latitude, currentLocation.coordinate.longitude);
    self.withinGeofences = NO;
    
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        for (geofencedPlace *place in myGeofences) {
            [locationManager requestStateForRegion:place.fenceRegion];
        }
        NSLog(@"within geofences: %i", self.withinGeofences);
    }];
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    [mainQueue addOperation:operation];
}



- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    NSLog(@"Now monitoring %@", region.identifier);
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    NSLog(@"Location manager determined state");
    
    if (state == CLRegionStateInside) {
        NSLog(@"Is inside %@", region.identifier);
        self.withinGeofences = YES;
        [self shareLocation:region.identifier];
    }
    else if (state == CLRegionStateOutside) {
        NSLog(@"Is outside region %@", region.identifier);
        
        CLCircularRegion *lastRegion = [[myGeofences lastObject] fenceRegion];

        if ([region isEqual:lastRegion] && self.withinGeofences == NO) {
            NSLog(@"Is outside all geofences");
            [self shareLocation:@"Other"];
        }
    }
    else if (state == CLRegionStateUnknown) {
        NSLog(@"State unknown");
        [self shareLocation:@"Unknown"];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Location mgr failed: %@", error);
    // Not updating to database since previous location will be shared
}

- (void)shareLocation:(NSString *)name {
    [[PFUser currentUser] setObject:name forKey:@"location"];
    [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) NSLog(@"Save succeeded");
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end


