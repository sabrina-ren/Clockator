//
//  SettingsViewController.m
//  Clockator
//
//  Created by Sabrina Ren on 12/23/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import "SettingsViewController.h"
#import "KeyConstants.h"
#import "FindFriendsViewController.h"
#import "PlaceIconViewController.h"
#import "Geofence.h"
#import "Place.h"
#import "UIColor+customColours.h"

@interface SettingsViewController ()
@property (nonatomic) GeofenceViewController *geofenceController;
@property (nonatomic) NSArray *settingsNames;
@property (nonatomic) NSArray *settingsControllers;
@property (nonatomic) NSIndexPath *selectedIndex;
@end

@implementation SettingsViewController
@synthesize clockPlaces, geofences;
@synthesize geofenceController, settingsNames, settingsControllers, selectedIndex;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 20, 40)];
    [titleLabel setFont:[UIFont fontWithName:@"DistrictPro-Thin" size:25]];
    [titleLabel setTextColor:[UIColor whiteColor]];
    [titleLabel setText:@"Settings"];
    self.navigationItem.titleView = titleLabel;
    self.clearsSelectionOnViewWillAppear = YES;
    settingsNames = @[@"Friends", @"Clock Face", @"Log Out"];

    FindFriendsViewController *findFriendsController = [self.storyboard instantiateViewControllerWithIdentifier:@"FindFriendsViewController"];
    findFriendsController.friendIds = self.friendIds;
    
    PlaceIconViewController *clockFaceController = [self.storyboard instantiateViewControllerWithIdentifier:@"PlaceIconViewController"];
    clockFaceController.clockPlaces = clockPlaces;
    clockFaceController.isIconView = NO;
    clockFaceController.delegate = self;
    
    settingsControllers = [NSArray arrayWithObjects:findFriendsController, clockFaceController, nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:animated];
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == 0) return geofences.count + 1;
    else if (section ==1) return settingsNames.count;
    return -1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if (indexPath.section == 0) {
        if (indexPath.row == geofences.count) {
            // Last row is to add a new place
            cell = [tableView dequeueReusableCellWithIdentifier:@"AddCell"];
            cell.textLabel.text = @"+";
            cell.textLabel.textColor = [UIColor customSalmon];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            [cell.textLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:25.0]];
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:@"SubtitleCell"];
            NSString *title = [geofences[indexPath.row] fenceName];
            cell.textLabel.text = title;
            cell.detailTextLabel.text = [geofences[indexPath.row] fenceAddress];
        }
    }
    else if (indexPath.section == 1) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
        NSString *title = settingsNames[indexPath.row];
        if (![title isEqualToString:@"Log Out"]) cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text = title;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        selectedIndex = indexPath;
        geofenceController = [self.storyboard instantiateViewControllerWithIdentifier:@"GeofenceViewController"];
        geofenceController.clockPlaces = clockPlaces;
        geofenceController.currentLocation = self.currentLocation;
        geofenceController.delegate = self;
        
        // If new place
        if (geofences.count == indexPath.row) geofenceController.geoPlace = nil;
        else geofenceController.geoPlace = geofences[indexPath.row];
        
        [self.navigationController pushViewController:geofenceController animated:YES];
    }
    else if (indexPath.section == 1) {
        if ([settingsNames[indexPath.row] isEqualToString:@"Log Out"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:CKNotificationShouldLogOut object:nil];
        }
        else [self.navigationController pushViewController:settingsControllers[indexPath.row] animated:YES];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) return @"My Places";
    return nil;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Second section is editable
    if (indexPath.section == 0 && indexPath.row != geofences.count) return YES;
    return NO;
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [self.delegate didUpdateGeofence:geofences[indexPath.row] changeType:deletedPlace];
        [geofences removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

#pragma mark - Update current location

- (void)didUpdateCurrentLocation:(CLLocation *)newLocation {
    geofenceController.currentLocation = newLocation;
    NSLog(@"YAY coordinates updated");
}

#pragma mark - MyPlaceViewController protocol

- (void)geofenceViewController:(GeofenceViewController *)controller didUpdateGeofence:(Geofence *)geofence isNew:(BOOL)isNew {
    if (isNew){
        [geofences addObject:geofence];
        [self.delegate didUpdateGeofence:geofence changeType:newPlace];
    }
    else {
        geofences[selectedIndex.row] = geofence;
        [self.delegate didUpdateGeofence:geofence changeType:changedPlace];
    }
    [self.tableView reloadData];
    
    if (isNew) {
        NSArray *indexPaths = [NSArray arrayWithObject:selectedIndex];
        [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationLeft];
    }
    for (Geofence *place in geofences) {
        NSLog(@"Geofences %@", place.fenceName);
    }
    
}

#pragma mark - PlaceIconController protocol

- (void)didChangeClockFace {
    [self.delegate didChangeClockFace];
}

- (void)placeIconController:(PlaceIconViewController *)controller didChangeIconIndex:(NSInteger)index {
    // For use with geofence view controller
}

@end
