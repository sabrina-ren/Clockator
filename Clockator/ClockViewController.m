//
//  ClockViewController.m
//  Clockator
//
//  Created by Sabrina Ren on 11/22/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import "ClockViewController.h"
#import "AppDelegate.h"
#import "FBFindFriendsController.h"
#import "CKFriend.h"
#import "Geofence.h"
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
@property (nonatomic) NSMutableArray *clockHands;
@property (nonatomic) NSMutableArray *handAngles;
@property (nonatomic) NSMutableArray *geofences;
@property (nonatomic) SettingsViewController *settingsController;

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

@property (nonatomic) CLLocation *currentLocation;
@property (nonatomic) CLLocationManager *locationManager;
@property NSInteger numShownPlaces;
@property double rotations;
@property BOOL didStartMonitoringRegion;
@property BOOL withinGeofences;
@property BOOL finishedLoadingFriends;

@end

@implementation ClockViewController
@synthesize friendsAtLocation, friendViews;
@synthesize clockPlaces, iconViews, myGeofences, clockHands, handAngles, geofences, settingsController;
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
    
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    self.managedObjectContext = appDelegate.managedObjectContext;
    myGeofences = [[NSMutableArray alloc] init];
    [self loadGeofences];
    
    // Get default clock places
    clockPlaces = [Place getDefaultPlaces];
    
//    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
//        [FBSession sessionOpen];
    FBCacheDescriptor *cacheDescriptor = [FBFindFriendsController cacheDescriptor];
    [cacheDescriptor prefetchAndCacheForSession:FBSession.activeSession];
//    }
    
    // Location Manager
    if ([self checkLocationServicesEnabledWithAlert:YES]) {
        [self setupLocationManager];
    }
    
    // Clear monitored locations
    for (CLRegion *oldRegion in locationManager.monitoredRegions) {
        [locationManager stopMonitoringForRegion:oldRegion];
    }
    
    [self monitorRegions];
    [self updateLocation:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBar.translucent = NO;
    
    // Remove old place icons
    for (UIImageView *imageView in iconViews) {
        [imageView removeFromSuperview];
    }
    // Remove old friend images
    for (UIButton *button in friendViews) {
        [button removeFromSuperview];
    }
    // Remove old clock hands
    for (UIImageView *imageView in clockHands) {
        [imageView removeFromSuperview];
    }
    self.finishedLoadingFriends = NO;

    [self loadShownClockPlaces];
    [self loadFriends];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [self showLoadingClockHands];
    if ([self checkLocationServicesEnabledWithAlert:NO] && !locationManager) [self setupLocationManager];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Core data 

- (void)loadGeofences {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Geofence" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    NSError *error;
    
    geofences = [NSMutableArray arrayWithArray:[self.managedObjectContext executeFetchRequest:fetchRequest error:&error]];
    NSLog(@"Fetched geofences:%i", geofences.count);
//    
//    for (Geofence *object in geofences) {
//        GeofencePlace *place = [[GeofencePlace alloc] init];
//        place.fenceRegion = object.fenceRegion;
//        place.fencePlacemark = object.fencePlacemark;
//        place.fenceName = object.fenceName;
//        place.iconIndex = object.iconIndex;
//        place.fenceRadius = object.fenceRadius;
//        [myGeofences addObject:place];
//        
//        [self.managedObjectContext deleteObject:object];
//    }
//    [self.managedObjectContext save:nil];
}

#pragma mark - UI Behaviour

- (void)loadShownClockPlaces {
    iconViews = [NSMutableArray arrayWithCapacity:clockPlaces.count];
    
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
    settingsController.geofences = geofences;
    settingsController.currentLocation = locationManager.location;
    settingsController.friendIds = friendIds;
    settingsController.delegate = self;
    [self.navigationController pushViewController:settingsController animated:YES];
}

- (void)showLoadingClockHands {
    clockHands = [[NSMutableArray alloc] init];
    UIImageView *newHand = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ClockHand.png"]];
    [newHand setFrame:CGRectMake(70, 215, 180, 7)];
    [clockHands addObject:newHand];
    [self.view addSubview:newHand];
    [self.view sendSubviewToBack:newHand];

    [self animateClockHand:newHand fromAngle:0 toAngle:M_PI*2 forDuration:0.8 withKey:@"full"];

}

- (void)animateClockHand:(UIImageView *)hand fromAngle:(double)fromAngle toAngle:(double)toAngle forDuration:(double)duration withKey:(NSString *)key {
    CABasicAnimation *rotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotation.fromValue = [NSNumber numberWithDouble:fromAngle];
    rotation.toValue = [NSNumber numberWithDouble:toAngle];
    rotation.duration = duration;
    rotation.cumulative = NO;
    rotation.fillMode = kCAFillModeForwards;
    rotation.removedOnCompletion = NO;
    rotation.delegate = self;
    [rotation setValue:key forKey:@"type"];
    [hand.layer setAnchorPoint:CGPointMake(0.5, 0.5)];
    [hand.layer addAnimation:rotation forKey:key];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    if (flag) NSLog(@"done");
    UIImageView *hand = [clockHands objectAtIndex:0];
    NSString *type = [anim valueForKey:@"type"];
    if ([type isEqualToString:@"full"]) {
        if (!self.finishedLoadingFriends)[self animateClockHand:hand fromAngle:0 toAngle:M_PI*2 forDuration:0.8 withKey:@"full"];
        
        else {
            [hand removeFromSuperview];
            [clockHands removeObjectAtIndex:0];
            NSLog(@"num angles:%i", handAngles.count);
            for (NSNumber *angle in handAngles) {
                
                UIImageView *newHand = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ClockHand.png"]];
                [newHand setFrame:CGRectMake(70, 215, 180, 7)];
                [clockHands addObject:newHand];
                [self.view addSubview:newHand];
                [self.view sendSubviewToBack:newHand];

                [self animateClockHand:newHand fromAngle:0 toAngle:M_PI*2 - [angle doubleValue] forDuration:0.4 withKey:@"partial"];
            }
        }
    }
    else {
        for (UIButton *button in friendViews) {
            [self.view addSubview:button];
            button.alpha = 0.1;
            [UIView beginAnimations:@"fadeIn" context:nil];
            [UIView setAnimationDuration:0.2];
            button.alpha = 1;
            [UIView commitAnimations];
        }
    }
}

#pragma mark - Friends data

- (void)loadFriends {
    friendViews = [[NSMutableArray alloc] init];
    
    NSLog(@"Loading friends");
    NSMutableArray *friendsIdList = [[PFUser currentUser] objectForKey:CKUserFriendsKey];
    [friendsIdList addObject:[PFUser currentUser].objectId];
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
        NSString *indexString = [friendUser objectForKey:CKUserIconKey];
        if (indexString) friend.iconIndex = [indexString intValue];
        else friend.iconIndex = 4;
        friend.updatedAt = [friendUser objectForKey:CKUserUpdateDateKey];
        // Sort friends by icon
        NSMutableArray *friendsAtIndex = friendsAtLocation[friend.iconIndex];
        [friendsAtIndex addObject:friend];
    }

    double locationAngle = 2*M_PI/numShownPlaces;
    
    int angleIndex = 0; // Tracks index of shown places not all clock places
    handAngles = [[NSMutableArray alloc] init];

    for (int i=0; i<clockPlaces.count; i++) {
        if (![clockPlaces[i] isShown]) continue;
        
        CKFriend *locatedFriend;
        if ([friendsAtLocation[i] count] > 0) {
            NSArray *friendsHere = friendsAtLocation[i];
            int numFriends = friendsHere.count;
            double offsetAngle = locationAngle/4;
            double offsetRadius = 10;
            
            double angle = - offsetAngle * numFriends/2 + offsetAngle * 0.5;
            angle += locationAngle*angleIndex + M_PI/2;
            
            for (int j=0; j<numFriends; j++) {
                double newAngle = angle;
                [handAngles addObject:[NSNumber numberWithDouble:newAngle]];
                locatedFriend = friendsHere[j];
                
                CGFloat radius =  80 - (j%2)*offsetRadius;
                
                CGFloat x = 140 + radius*cos(angle);
                CGFloat y = 200 - radius*sin(angle);
                angle += offsetAngle;
                
                UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                [button setImage:locatedFriend.profile forState:UIControlStateNormal];
                [button addTarget:self action:@selector(friendButtonTouchHandler:) forControlEvents:UIControlEventTouchUpInside];
                button.tag = (i+1)*100 + j; // Num friends will not exceed 99
                button.frame = CGRectMake(x, y, 50, 50);
                button.clipsToBounds = YES;
                button.layer.cornerRadius = 25;
                
//                [self.view addSubview:button];
                [friendViews addObject:button];
            }
        }
        angleIndex++;
    }
    self.finishedLoadingFriends = YES;

}
- (void)friendButtonTouchHandler:(id)sender {
    UIButton *button = (UIButton *)sender;
    
    NSString *indexString = [NSString stringWithFormat:@"%i", button.tag];
    NSInteger friendIndex = [[indexString substringFromIndex:indexString.length - 2] integerValue];
    NSInteger locationIndex = (button.tag - friendIndex)/100 - 1;
    [[button superview] bringSubviewToFront:button];
    
    CKFriend *locatedFriend = [friendsAtLocation[locationIndex] objectAtIndex:friendIndex];
    CGPoint point = CGPointMake(button.frame.origin.x + 25, button.frame.origin.y - 5);
    NSString *text = [NSString stringWithFormat:@"%@\n%@ %@", locatedFriend.displayName, locatedFriend.location, locatedFriend.locationUpdatedAt];
    PopoverView *detailView = [PopoverView showPopoverAtPoint:point inView:self.view withText:text delegate:nil];
}

#pragma mark - Location manager methods

- (void)setupLocationManager {
    locationManager = [[CLLocationManager alloc] init];
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.delegate = self;
    [locationManager startUpdatingLocation];
    currentLocation = locationManager.location;
}

- (void)monitorRegions {
    for (Geofence *place in geofences) {
        [locationManager startMonitoringForRegion:place.fenceRegion];
    }
//    for (GeofencePlace *place in myGeofences) {
//        [locationManager startMonitoringForRegion:place.fenceRegion];
//    }
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    NSLog(@"Now monitoring %@", region.identifier);
}

- (IBAction)updateLocation:(id)sender {
    self.withinGeofences = NO;

    NSLog(@"Num monitored regions: %i", locationManager.monitoredRegions.count);
    if (locationManager.monitoredRegions.count == 0) [self shareLocation:@"Unknown" iconIndex:@"4"];
    
    for (Geofence *place in geofences) {
        [locationManager requestStateForRegion:place.fenceRegion];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if ([currentLocation distanceFromLocation:locationManager.location] > 50) {
        // Register location change if greater than 50m
        NSLog(@"Location changed");
        [self updateLocation:nil];
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
            [self shareLocation:@"Other" iconIndex:@"4"];
        }
    }
    else if (state == CLRegionStateUnknown) {
        NSLog(@"State unknown");
        // No update to database since previous location will be shared
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Location mgr failed: %@", error);
    [self checkLocationServicesEnabledWithAlert:YES];
    // No update to database since previous location will be shared
}

- (BOOL)checkLocationServicesEnabledWithAlert:(BOOL)showAlert {
    NSString *title;
    NSString *message;
    if (![CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]]) {
        title = @"This phone does not support region monitoring";
        message = @"You can still receive updates from friends";
    }
    if (![CLLocationManager locationServicesEnabled] || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        title = @"Location Services Disabled";
        message = @"Go to Settings > Privacy to allow";
    }
    else return YES;
    
    if (showAlert) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    return NO;
}

#pragma mark - Parse database

- (void)shareLocation:(NSString *)name iconIndex:(NSString *)index {
    [[PFUser currentUser] setObject:name forKey:@"location"];
    [[PFUser currentUser] setObject:index forKey:@"iconIndex"];
    [[PFUser currentUser] setObject:[NSDate date] forKey:CKUserUpdateDateKey];
    [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) NSLog(@"Save succeeded");
    }];
}

#pragma mark - SetingsViewController protocol method

- (void)didUpdateGeofence:(Geofence *)geofence changeType:(ChangeType)type {
    if (type == deletedPlace || type == changedPlace) {
        [locationManager stopMonitoringForRegion:geofence.fenceRegion];
        if (type == deletedPlace) [self.managedObjectContext deleteObject:geofence];
    }
    if (type == newPlace || type == changedPlace) {
        [locationManager startMonitoringForRegion:geofence.fenceRegion];
    }
    [self.managedObjectContext save:nil];

    NSLog(@"Did update num monitored regions: %i", locationManager.monitoredRegions.count);
}

@end


