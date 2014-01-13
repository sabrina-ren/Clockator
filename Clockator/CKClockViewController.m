//
//  CKClockViewController.m
//  Clockator
//
//  Created by Sabrina Ren on 11/22/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import "CKClockViewController.h"
#import "CKAppDelegate.h"
#import "CKFriend.h"
#import "CKGeofence.h"
#import "CKAppConstants.h"
#import "CKLoginViewController.h"
#import "CKPlace.h"
#import "Reachability.h"
#import "CKSettingsViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface CKClockViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *clockCircle;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) CKSettingsViewController *settingsController;

@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) CLLocation *currentLocation;

@property (nonatomic) NSMutableArray *clockHands;
@property (nonatomic) NSMutableArray *clockPlaces;
@property (nonatomic) NSMutableArray *friendsAtLocation;
@property (nonatomic) NSMutableArray *friendViews;
@property (nonatomic) NSMutableArray *geofences;
@property (nonatomic) NSMutableArray *handAngles;
@property (nonatomic) NSMutableArray *iconViews;
@property (nonatomic) NSMutableArray *myGeofences;

@property NSInteger numShownPlaces;
@property double rotations;
@property int userHandIndex;
@property int rounds;
@property BOOL didStartMonitoringRegion;
@property BOOL withinGeofences;
@property BOOL finishedLoadingFriends;
@end

@implementation CKClockViewController
@synthesize friendsAtLocation, friendViews;
@synthesize clockPlaces, iconViews, myGeofences, clockHands, handAngles, geofences, settingsController;
@synthesize friendIds;
@synthesize currentLocation, locationManager, numShownPlaces;

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"clock view did load");

    // Appearance setup
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 20, 40)];
    [titleLabel setFont:[UIFont fontWithName:@"DistrictPro-Thin" size:27]];
    [titleLabel setTextColor:[UIColor whiteColor]];
    [titleLabel setText:@"CLOCKATOR"];
    self.navigationItem.titleView = titleLabel;
    
    UIButton *settingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [settingsButton setImage:[UIImage imageNamed:@"Menu"] forState:UIControlStateNormal];
    [settingsButton addTarget:self action:@selector(settingsButtonTouchHandler:) forControlEvents:UIControlEventTouchUpInside];
    settingsButton.frame = CGRectMake(0, 0, 25, 22);
    UIBarButtonItem *settingsItem = [[UIBarButtonItem alloc] initWithCustomView:settingsButton];
    self.navigationItem.rightBarButtonItem = settingsItem;
    
    UIButton *refreshButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [refreshButton setImage:[UIImage imageNamed:@"Refresh"] forState:UIControlStateNormal];
    [refreshButton addTarget:self action:@selector(refreshButtonTouchHandler:) forControlEvents:UIControlEventTouchUpInside];
    refreshButton.frame = CGRectMake(0, 0, 24, 26);
    UIBarButtonItem *refreshItem = [[UIBarButtonItem alloc] initWithCustomView:refreshButton];
    self.navigationItem.leftBarButtonItem = refreshItem;
    
    CKAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    self.managedObjectContext = appDelegate.managedObjectContext;
    myGeofences = [[NSMutableArray alloc] init];
    [self loadGeofences];
    
    self.isReachable = YES; // Assume connected until confirmed no
  
    // Notification observers
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearGeofences) name:CKNotificationShouldLogOut object:nil];
    
    // Clear monitored locations
    for (CLRegion *oldRegion in locationManager.monitoredRegions) {
        [locationManager stopMonitoringForRegion:oldRegion];
    }
    
    self.finishedLoadingFriends = NO;
    [self loadShownClockPlaces];
    [self showLoadingClockHands];
    [self refreshFriends];
    
    [self monitorRegions];
//    [self updateLocation:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBar.translucent = NO;
    NSLog(@"view will appear");

    if (self.shouldRefreshClock) {
        NSLog(@"Refresh");
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
    }
}

- (void)viewDidAppear:(BOOL)animated {
    if ([self checkLocationServicesEnabledWithAlert:NO] && !locationManager && [PFUser currentUser]) [self setupLocationManager];
    if (self.shouldRefreshClock) {
        NSLog(@"Should refresh clock");
        self.shouldRefreshClock = NO;
        [self showLoadingClockHands];
        [self refreshFriends];
        [self updateLocation:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Reachability

- (void)reachabilityChanged:(NSNotification *)notification {
    Reachability *reach = (Reachability *)[notification object];
    if ([reach isKindOfClass:[Reachability class]]) {
        NetworkStatus internetStatus = [reach currentReachabilityStatus];
        
        if (internetStatus == NotReachable) {
            if (self.isReachable) { // If internet was previously available
                NSLog(@"Clock view not reachable");
                
                NSString *title = @"No Internet Connection";
                NSString *message = @"Clock will be refreshed when reconnected";
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alert show];
            }
            self.isReachable = NO;
        }
        else {
            if (!self.isReachable){
                self.isReachable = YES;
                // Refresh if internet wasn't previously reachable
                [self refreshButtonTouchHandler:nil];
            }
            currentLocation = locationManager.location;
            [settingsController didUpdateCurrentLocation:currentLocation];
            self.isReachable = YES;
        }
        NSLog(@"Reachability changed to: %i", self.isReachable);
        settingsController.isReachable = self.isReachable;
        ((CKLoginViewController *)self.presentedViewController).isReachable = self.isReachable;
    }
}

#pragma mark - Core data

- (void)loadGeofences {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"CKGeofence" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    NSError *error;
    geofences = [NSMutableArray arrayWithArray:[self.managedObjectContext executeFetchRequest:fetchRequest error:&error]];
    NSLog(@"Fetched geofences:%lu", (unsigned long)geofences.count);
}

- (void)clearGeofences {    
    for (CLRegion *oldRegion in locationManager.monitoredRegions) {
        [locationManager stopMonitoringForRegion:oldRegion];
    }
    for (CKGeofence *fence in geofences) {
        [self.managedObjectContext deleteObject:fence];
    }
    [self.managedObjectContext save:nil];
    [geofences removeAllObjects];
}

#pragma mark - UI Behaviour

- (void)loadShownClockPlaces {
    clockPlaces = [CKPlace getDefaultPlaces];
    iconViews = [NSMutableArray arrayWithCapacity:clockPlaces.count];
    
    numShownPlaces = 0;
    for (CKPlace *thisPlace in clockPlaces) {
        if (thisPlace.isShown) numShownPlaces++;
    }
    double angle = 2*M_PI/numShownPlaces;
    
    int angleIndex = 0; // Tracks index of shown places not all clock places
    CGFloat iconSize = 40;
    
    for (int i=0; i<clockPlaces.count; i++) {
        if (![clockPlaces[i] isShown]) continue;
        CGFloat locRadius = self.clockCircle.frame.size.width/2 - 7;
        
        CGFloat x = 140 + locRadius*cos(angle*angleIndex + M_PI/2);
        CGFloat y = [UIScreen mainScreen].bounds.size.height/2 - 50 - locRadius*sin(angle*angleIndex + M_PI/2);
        
        UIView *placeV = [[UIView alloc] initWithFrame:CGRectMake(x,y,iconSize, iconSize)];
        UIImageView *imgV = [[UIImageView alloc] initWithImage:[clockPlaces[i] placeIcon]];
        [imgV setFrame:CGRectMake(0, 0, 40, 30)];
        [placeV addSubview:imgV];
        [[self view] addSubview:placeV];
        [iconViews addObject:placeV];
        angleIndex++;
    }
}

- (void)refreshButtonTouchHandler:(id)sender {
    NSLog(@"Refresh");
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
//        [imageView.layer removeAllAnimations];
    }
    self.finishedLoadingFriends = NO;
    
    [self loadShownClockPlaces];
    [self refreshFriends];
    [self showLoadingClockHands];
    [self updateLocation:nil];
}

- (void)settingsButtonTouchHandler:(id)sender {
    settingsController = [self.storyboard instantiateViewControllerWithIdentifier:@"SettingsViewController"];
    settingsController.clockPlaces = clockPlaces;
    settingsController.geofences = geofences;
    settingsController.currentLocation = locationManager.location;
    settingsController.friendIds = friendIds;
    settingsController.isReachable = self.isReachable;
    settingsController.delegate = self;
    [self.navigationController pushViewController:settingsController animated:YES];
}

- (void)showLoadingClockHands {
    clockHands = [[NSMutableArray alloc] init];
    UIImageView *newHand = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ClockHand.png"]];
    CGRect screen = [[UIScreen mainScreen] bounds];
    [newHand setFrame:CGRectMake(screen.size.width/4 - 10, screen.size.height/2 - 35, 180, 7)];
    [clockHands addObject:newHand];
    [self.view addSubview:newHand];
    [self.view sendSubviewToBack:newHand];

    self.rounds = 0;
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
    if (flag) {
        NSLog(@"Animation stopped");
        self.rounds++;
        UIImageView *hand = [clockHands objectAtIndex:0];
        NSString *type = [anim valueForKey:@"type"];
        
        if ([type isEqualToString:@"full"]) {
            if (!self.isReachable) {
                // Animation stops
            }
            else if (self.rounds > 20) {
                // Give up after 20 rounds
                // Animation stops
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Could not connect" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alert show];
            }
            else if (!self.finishedLoadingFriends)[self animateClockHand:hand fromAngle:0 toAngle:M_PI*2 forDuration:0.8 withKey:@"full"];
            else {
                [hand removeFromSuperview];
                [clockHands removeObjectAtIndex:0];
                NSLog(@"num angles:%i", handAngles.count);
                
                for (int i=0; i<handAngles.count; i++) {
                    NSString *imageName = @"ClockHand";
                    if (i == self.userHandIndex) imageName = @"userClockHand";
                    
                    UIImageView *newHand = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
                    CGRect screen = [[UIScreen mainScreen] bounds];
                    [newHand setFrame:CGRectMake(screen.size.width/4 - 10, screen.size.height/2 - 35, 180, 7)];
                    [clockHands addObject:newHand];
                    [self.view addSubview:newHand];
                    if (i == self.userHandIndex) [self.view bringSubviewToFront:newHand];
                    else [self.view sendSubviewToBack:newHand];
                    
                    [self animateClockHand:newHand fromAngle:0 toAngle:M_PI*2 - [handAngles[i] doubleValue] forDuration:0.4 withKey:@"partial"];
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
}

#pragma mark - Friends data

- (void)refreshFriends {

    if (self.isReachable && [PFUser currentUser]) {
        [[PFUser currentUser] refreshInBackgroundWithTarget:self selector:@selector(loadFriends)];
    }
}

- (void)loadFriends {
    friendViews = [[NSMutableArray alloc] init];
    
    NSLog(@"Loading friends");
    PFUser *user = [PFUser currentUser];
    NSMutableArray *friendsIdList = [[NSMutableArray alloc] init];
    friendsIdList = user[@"friends"];
    
    if (!friendsIdList) friendsIdList = [[NSMutableArray alloc] init];
    NSLog(@"num added friends: %i", friendsIdList.count);
    
    NSMutableArray *allUsers = [NSMutableArray arrayWithArray:friendsIdList];
    
    [allUsers addObject:[PFUser currentUser].objectId]; // Add current user to clock too
    NSMutableArray *friends = [[NSMutableArray alloc] init];
    
    PFQuery *query = [PFUser query];
    [query whereKey:CKUserObjectId containedIn:allUsers];
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
        else friend.iconIndex = clockPlaces.count-1;
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
            double offsetRadius = 8;
            
            double angle = - offsetAngle * numFriends/2 + offsetAngle * 0.5;
            angle += locationAngle*angleIndex + M_PI/2;
            
            for (int j=0; j<numFriends; j++) {
                double newAngle = angle;
                locatedFriend = friendsHere[j];
                if ([locatedFriend.displayName isEqualToString:[[PFUser currentUser] objectForKey:CKUserDisplayNameKey]]) self.userHandIndex = handAngles.count;
                [handAngles addObject:[NSNumber numberWithDouble:newAngle]];

                
                CGFloat radius =  76 - (j%2)*offsetRadius;
                CGFloat buttonSize = 50;
                
                CGFloat x = 135 + radius*cos(angle);
                CGFloat y = [UIScreen mainScreen].bounds.size.height/2 - 55 - radius*sin(angle);
                angle += offsetAngle;
                
                UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                [button setImage:locatedFriend.profile forState:UIControlStateNormal];
                [button addTarget:self action:@selector(friendButtonTouchHandler:) forControlEvents:UIControlEventTouchUpInside];
                button.tag = (i+1)*100 + j; // Num friends will not exceed 99
                button.frame = CGRectMake(x, y, buttonSize, buttonSize);
                button.clipsToBounds = YES;
                button.layer.cornerRadius = 25;
                
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
    NSString *locationName = locatedFriend.location;
    if (!locationName) locationName = @"Unknown";
    NSString *text = [NSString stringWithFormat:@"%@\n%@ %@", locatedFriend.displayName, locationName, locatedFriend.locationUpdatedAt];
    [PopoverView showPopoverAtPoint:point inView:self.view withText:text delegate:nil];
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
    for (CKGeofence *place in geofences) {
        [locationManager startMonitoringForRegion:place.fenceRegion];
    }
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    NSLog(@"Now monitoring %@", region.identifier);
}

- (void)updateLocation:(id)sender {
    if (self.isReachable && [PFUser currentUser]) {
        self.withinGeofences = NO;
        
        NSLog(@"Num monitored regions: %i", locationManager.monitoredRegions.count);
        if (locationManager.monitoredRegions.count == 0) [self shareLocation:@"Unknown" iconIndex:[NSString stringWithFormat:@"%i", clockPlaces.count-1]];

        for (CKGeofence *place in geofences) {
            [locationManager requestStateForRegion:place.fenceRegion];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if ([currentLocation distanceFromLocation:locationManager.location] > 20) {
        // Register location change if greater than 20m
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
        
        CLCircularRegion *lastRegion = [[geofences lastObject] fenceRegion];
        if ([region isEqual:lastRegion] && self.withinGeofences == NO) {
            NSLog(@"Is outside all geofences");
            [self shareLocation:@"Other" iconIndex:[NSString stringWithFormat:@"%i", clockPlaces.count-1]];
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
        message = @"Unable to update your location\nGo to Settings > Privacy to allow";
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
    if ([PFUser currentUser]) {
        [[PFUser currentUser] setObject:name forKey:CKUserLocationKey];
        [[PFUser currentUser] setObject:index forKey:CKUserIconKey];
        [[PFUser currentUser] setObject:[NSDate date] forKey:CKUserUpdateDateKey];
        [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) NSLog(@"Save succeeded");
        }];
    }
}

#pragma mark - SetingsViewController protocol

- (void)didUpdateGeofence:(CKGeofence *)geofence changeType:(ChangeType)type {
    if (type == deletedPlace || type == changedPlace) {
        [locationManager stopMonitoringForRegion:geofence.fenceRegion];
        if (type == deletedPlace) [self.managedObjectContext deleteObject:geofence];
    }
    if (type == newPlace || type == changedPlace) {
        [locationManager startMonitoringForRegion:geofence.fenceRegion];
    }
    [self.managedObjectContext save:nil];
    NSLog(@"Did update num monitored regions: %i", locationManager.monitoredRegions.count);
    
    self.shouldRefreshClock = YES;
}

- (void)didChangeClockFace {
    self.shouldRefreshClock = YES;
}

@end


