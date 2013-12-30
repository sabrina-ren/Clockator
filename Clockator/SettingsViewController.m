//
//  SettingsViewController.m
//  Clockator
//
//  Created by Sabrina Ren on 12/23/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import "SettingsViewController.h"
#import "FBFindFriendsController.h"
#import "PlaceIconViewController.h"
#import "GeofencePlace.h"
#import "Place.h"
#import "UIColor+customColours.h"

@interface SettingsViewController ()
@property (nonatomic) GeofenceViewController *geofenceController;
@property (nonatomic) NSArray *settingsNames;
@property (nonatomic) NSArray *settingsControllers;
@property (nonatomic) NSInteger selectedRow;
@end

@implementation SettingsViewController
@synthesize clockPlaces, myGeofences;
@synthesize geofenceController, settingsNames, settingsControllers;

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
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 10, 40)];
    [titleLabel setTextColor:[UIColor whiteColor]];
    [titleLabel setText:@"Settings"];
    self.navigationItem.titleView = titleLabel;

    settingsNames = @[@"Find Friends", @"Clock Face"];
    
    FBFindFriendsController *findFriendsController = [[FBFindFriendsController alloc] init];
    [findFriendsController loadData];

    PlaceIconViewController *clockFaceController = [self.storyboard instantiateViewControllerWithIdentifier:@"PlaceIconViewController"];
    clockFaceController.clockPlaces = clockPlaces;
    clockFaceController.isIconView = NO;
    
    settingsControllers = [NSArray arrayWithObjects:findFriendsController, clockFaceController, nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#warning Potentially incomplete method implementation.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    if (section == 0) return settingsNames.count;
    else if (section ==1) return myGeofences.count + 1;
    return -1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if (indexPath.section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        NSString *title = settingsNames[indexPath.row];
        cell.textLabel.text = title;
    }
    else if (indexPath.section == 1) {
        if (indexPath.row == myGeofences.count) {
            // Last row is to add a new place
            cell = [tableView dequeueReusableCellWithIdentifier:@"AddCell"];
            cell.textLabel.text = @"+";
            cell.textLabel.textColor = [UIColor customTurquoise];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            [cell.textLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:25.0]];
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:@"SubtitleCell"];
            NSString *title = [myGeofences[indexPath.row] fenceName];
            cell.textLabel.text = title;
            cell.detailTextLabel.text = [myGeofences[indexPath.row] fenceAddress];
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        [self.navigationController pushViewController:settingsControllers[indexPath.row] animated:YES];
    } else {
        self.selectedRow = indexPath.row;
         geofenceController = [self.storyboard instantiateViewControllerWithIdentifier:@"GeofenceViewController"];
        geofenceController.clockPlaces = clockPlaces;
        geofenceController.currentLocation = self.currentLocation;
        geofenceController.delegate = self;

        // If new place
        if (myGeofences.count == indexPath.row) geofenceController.geoPlace = nil;
        else geofenceController.geoPlace = myGeofences[indexPath.row];
  
        [self.navigationController pushViewController:geofenceController animated:YES];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 1) return @"My Places";
    return nil;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Second section is editable
    if (indexPath.section == 1 && indexPath.row != myGeofences.count) return YES;
    return NO;
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [self.delegate didUpdateGeofence:myGeofences[indexPath.row] changeType:deletedPlace];
        [myGeofences removeObjectAtIndex:indexPath.row];

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

#pragma mark - MyPlaceViewController protocol method

- (void)geofenceViewController:(GeofenceViewController *)controller didUpdateGeofence:(GeofencePlace *)geofence isNew:(BOOL)isNew {
    if (isNew){
        [myGeofences addObject:geofence];
        [self.delegate didUpdateGeofence:geofence changeType:newPlace];
    }
    else {
        myGeofences[self.selectedRow] = geofence;
        [self.delegate didUpdateGeofence:geofence changeType:changedPlace];
    }
    [self.tableView reloadData];
    
    if (isNew) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:self.selectedRow inSection:1];
        NSArray *indexPaths = [NSArray arrayWithObject:path];
        [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationLeft];
    }
    for (GeofencePlace *place in myGeofences) {
        NSLog(@"Geofences %@", place.fenceName);
    }
    
}

@end
