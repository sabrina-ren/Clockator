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
@property BOOL didStartMonitoringRegion;
@property (nonatomic) NSMutableArray *geofences;

@end

@implementation ClockViewController
@synthesize locations, friends, friendsAtLocation, hands, placeViews;
@synthesize clockPlaces, myGeofences, locationManager;

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
    
//    CGRect screenRect = [[UIScreen mainScreen] bounds];
//    CGFloat screenWidth = screenRect.size.width;
//    CGFloat screenHeight = screenRect.size.height;
//    NSLog(@"%f",screenWidth);
    
    // Temp hardcoded data for demo
    friends = appDelegate.friends;
    locations = appDelegate.locations;
    friendsAtLocation = appDelegate.friendsAtLocation;
    
    
    NSInteger numPlaces = 0; // Number of shown places is different from total number of potentially shown places
    for (Place *thisPlace in clockPlaces) {
        if (thisPlace.isShown) numPlaces++;
    }
    placeViews = [NSMutableArray arrayWithCapacity:clockPlaces.count];
    double angle = 2*M_PI/numPlaces;
    int angleIndex = 0; // Separate index to track index of shown places
    
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
        
        if ([friendsAtLocation[i] count]==1) {
            CGFloat radius = 90;
            x = 140 + radius*cos(angle*i + M_PI/2);
            y = 200 - radius*sin(angle*i + M_PI/2);
            
            UIImageView *newHand = [[UIImageView alloc] initWithImage: [UIImage imageNamed:@"hand.png"]];
            [newHand setFrame:CGRectMake(52, 215, 217, 10)];
            [hands addObject:newHand];
            [[self view] addSubview:newHand];
            [self.view sendSubviewToBack:newHand];
            
//            CABasicAnimation *rotationAnimation;
//            rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
//            rotationAnimation.toValue = [NSNumber numberWithFloat:angle*(-i)+M_PI/2+M_PI*3];
//            rotationAnimation.duration = 1.5;
//            rotationAnimation.cumulative = NO;
//            rotationAnimation.fillMode = kCAFillModeForwards;
//            rotationAnimation.removedOnCompletion = NO;
//            [newHand.layer setAnchorPoint:CGPointMake(0.5,0.5)];
//            [newHand.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
            
            
            // Temp hardcoded friend data
            Friend *locatedFriend = [[Friend alloc] init];
            locatedFriend = [friendsAtLocation[i] objectAtIndex:0];
            UIView *friendView = [[UIView alloc] initWithFrame:CGRectMake(x,y,2,40)];
            UIImageView *friendImage = [[UIImageView alloc] initWithImage:locatedFriend.picture];
            [friendImage setFrame:CGRectMake(0,0,45,45)];
            [friendView addSubview:friendImage];
            [[self view] addSubview:friendView];
        }
        angleIndex++;
    }
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
    [self monitorRegions];

    self.geofences = [NSMutableArray arrayWithArray:[[self.locationManager monitoredRegions] allObjects]];
}

- (void)viewWillAppear:(BOOL)animated {
    [self loadShownPlaces];
    [self monitorRegions];

    for (geofencedPlace *place in myGeofences) {
        NSLog(@"Clock View geofences %@", place.fenceName);
    }
}

- (void)viewDidAppear:(BOOL)animated {

}

- (void)loadShownPlaces {
    for (UIImageView *imgV in placeViews) {
        [imgV removeFromSuperview];
    }
    placeViews = [NSMutableArray arrayWithCapacity:clockPlaces.count];
    
    NSInteger numPlaces = 0;
    for (Place *thisPlace in clockPlaces) {
        if (thisPlace.isShown) numPlaces++;
    }
    double angle = 2*M_PI/numPlaces;
    
    int angleIndex = 0;
    
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
    [self.navigationController pushViewController:settingsController animated:YES];
}

- (void)monitorRegions {
    for (geofencedPlace *place in myGeofences) {
        [locationManager startMonitoringForRegion:place.fenceRegion];
    }
}

- (IBAction)updateLocation:(id)sender {
    NSLog(@"%f, %f", locationManager.location.coordinate.latitude, locationManager.location.coordinate.longitude);
    geofencedPlace *place = myGeofences[0];
    [locationManager requestStateForRegion:place.fenceRegion];
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    NSLog(@"Now monitoring %@", region.identifier);
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    NSLog(@"Location manager determined state");
    
    if (state == CLRegionStateInside) {
        NSLog(@"is inside region");
        [[PFUser currentUser] setObject:region.identifier forKey:@"location"];
        [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) NSLog(@"Save succeeded");
        }];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end


