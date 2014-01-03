//
//  ClockViewController.m
//  Clockator
//
//  Created by Sabrina Ren on 11/22/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import "ClockViewController.h"
#import "FBFindFriendsController.h"
#import "CKFriend.h"
#import "GeofencePlace.h"
#import "KeyConstants.h"
#import "LoginViewController.h"
#import "Place.h"
#import "SettingsViewController.h"
#import <QuartzCore/QuartzCore.h>


@interface ClockViewController ()
@property (nonatomic) NSMutableArray *friendsAtLocation;
@property (nonatomic) NSMutableArray *friendViews;

@property (nonatomic) NSMutableArray *clockPlaces;
@property (nonatomic) NSMutableArray *iconViews;
@property (nonatomic) NSMutableArray *myGeofences;
@property (nonatomic, retain) NSMutableArray *hands;
@property (nonatomic) SettingsViewController *settingsController;

@property (nonatomic) CLLocation *currentLocation;
@property (nonatomic) CLLocationManager *locationManager;
@property NSInteger numShownPlaces;
@property BOOL didStartMonitoringRegion;
@property BOOL withinGeofences;

@end

@implementation ClockViewController
@synthesize friendsAtLocation, friendViews;
@synthesize clockPlaces, iconViews, myGeofences, hands, settingsController;
@synthesize friendIds;
@synthesize currentLocation, locationManager, numShownPlaces;

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

//    [self loadShownClockPlaces];
//    [self loadFriends];
    
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
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBar.translucent = NO;
    
    // Remove old place icons
    for (UIImageView *imageView in iconViews) {
        [imageView removeFromSuperview];
    }
    // Remove old friend images
    for (UIImageView *imageView in friendViews) {
        [imageView removeFromSuperview];
    }
    
    [self loadShownClockPlaces];
    [self loadFriends];
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
    
    numShownPlaces = 0;
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

#pragma mark - Friends data

- (void)loadFriends {
    friendViews = [[NSMutableArray alloc] init];
    
    NSLog(@"Loading friends");
    NSArray *friendsIdList = [[PFUser currentUser] objectForKey:CKUserFriendsKey];
    NSMutableArray *friends = [[NSMutableArray alloc] init];
    
    PFQuery *query = [PFUser query];
    [query whereKey:CKUserObjectId containedIn:friendsIdList];
     [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
         if (!error) {
             for (PFUser *user in objects) {
             [friends addObject:user];
             }
             [self loadLocationsForFriends:friends];
         }
     }];
}

- (void)loadLocationsForFriends:(NSMutableArray *)friends {
    friendsAtLocation = [[NSMutableArray alloc] init];
    for (int i=0; i<clockPlaces.count; i++) {
        [friendsAtLocation addObject:[[NSMutableArray alloc] init]];
    }
    
    for (PFUser *friendUser in friends) {
        CKFriend *friend = [[CKFriend alloc] init];
        friend.displayName = [friendUser objectForKey:CKUserDisplayNameKey];
        friend.location = [friendUser objectForKey:CKUserLocationKey];
        friend.profile = [UIImage imageWithData:[friendUser objectForKey:CKUserProfileKey]];
        friend.iconIndex = [[friendUser objectForKey:CKUserIconKey] intValue];
        
        // Sort friends by icon
        NSMutableArray *friendsAtIndex = friendsAtLocation[friend.iconIndex];
        [friendsAtIndex addObject:friend];
    }

    double locationAngle = 2*M_PI/numShownPlaces;
    
    int angleIndex = 0; // Tracks index of shown places not all clock places
    
    for (int i=0; i<clockPlaces.count; i++) {
        if (![clockPlaces[i] isShown]) continue;
        
        CKFriend *locatedFriend;
        if ([friendsAtLocation[i] count] > 0) {
            NSArray *friendsHere = friendsAtLocation[i];
            int numFriends = friendsHere.count;
            double offsetAngle = locationAngle/4;
            double offsetRadius = 10;
            
            double angle = - offsetAngle * numFriends/2 + offsetAngle * 0.5;
            
            for (int j=0; j<numFriends; j++) {
                locatedFriend = friendsHere[j];
                
                CGFloat radius =  80 - (j%2)*offsetRadius;
                
                CGFloat x = 140 + radius*cos(locationAngle*angleIndex + M_PI/2 + angle);
                CGFloat y = 200 - radius*sin(locationAngle*angleIndex + M_PI/2 + angle);
                angle += offsetAngle;
                
                UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                [button setImage:locatedFriend.profile forState:UIControlStateNormal];
                [button addTarget:self action:@selector(friendButtonTouchHandler:) forControlEvents:UIControlEventTouchUpInside];
                button.tag = (i+1)*100 + j; // Num friends will not exceed 99
                button.frame = CGRectMake(x, y, 50, 50);
                button.clipsToBounds = YES;
                button.layer.cornerRadius = 25;
                
                [self.view addSubview:button];
                [friendViews addObject:button];
            }
        }
        angleIndex++;
    }

}
- (void)friendButtonTouchHandler:(id)sender {
    UIButton *button = (UIButton *)sender;
    
    NSString *indexString = [NSString stringWithFormat:@"%i", button.tag];
    NSInteger friendIndex = [[indexString substringFromIndex:indexString.length - 2] integerValue];
    NSInteger locationIndex = (button.tag - friendIndex)/100 - 1;
    [[button superview] bringSubviewToFront:button];
    
    CKFriend *locatedFriend = [friendsAtLocation[locationIndex] objectAtIndex:friendIndex];
    CGPoint point = CGPointMake(button.frame.origin.x + 25, button.frame.origin.y - 5);
    NSString *text = [NSString stringWithFormat:@"%@\n%@", locatedFriend.displayName, locatedFriend.location];
    PopoverView *detailView = [PopoverView showPopoverAtPoint:point inView:self.view withText:text delegate:nil];
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


