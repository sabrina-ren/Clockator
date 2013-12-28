//
//  SettingsViewController.m
//  Clockator
//
//  Created by Sabrina Ren on 12/23/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import "SettingsViewController.h"
#import "FBFindFriendsController.h"
#import "ClockFaceSettingsController.h"
#import "Place.h"
#import "geofencedPlace.h"
#import "UIColor+customColours.h"

@interface SettingsViewController ()

@property (nonatomic) NSArray *settingsNames;
@property (nonatomic) NSArray *settingsControllers;
@property (nonatomic) NSInteger selectedRow;

@end

@implementation SettingsViewController
@synthesize settingsNames, settingsControllers, clockPlaces, myGeofences;
//@synthesize delegate;

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

    ClockFaceSettingsController *clockFaceController = [self.storyboard instantiateViewControllerWithIdentifier:@"ClockFaceSettingsController"];
    clockFaceController.clockPlaces = clockPlaces;
    settingsControllers = [NSArray arrayWithObjects:findFriendsController, clockFaceController, nil];
    
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - MyPlaceViewController protocol method

- (void)myPlacesViewController:(MyPlacesViewController *)controller didUpdateGeofence:(geofencedPlace *)geofence isNew:(BOOL)isNew {

    if (isNew)[myGeofences addObject:geofence];
    else myGeofences[self.selectedRow] = geofence;
   
    [self.tableView reloadData];
    
    if (isNew) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:self.selectedRow inSection:1];
        NSArray *indexPaths = [NSArray arrayWithObject:path];
        [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationLeft];
    }
    for (geofencedPlace *place in myGeofences) {
        NSLog(@"Geofences %@", place.fenceName);
    }
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
    } else if (indexPath.section == 1) {
        if (indexPath.row == myGeofences.count) {
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
         MyPlacesViewController *myPlacesController = [self.storyboard instantiateViewControllerWithIdentifier:@"MyPlacesViewController"];
        myPlacesController.currentLocation = self.currentLocation;
        if (myGeofences.count == indexPath.row) myPlacesController.geoPlace = nil;
        else myPlacesController.geoPlace = myGeofences[indexPath.row];
        
        myPlacesController.delegate = self;
        [self.navigationController pushViewController:myPlacesController animated:YES];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 1) return @"My Places";
    return nil;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    if (indexPath.section == 1 && indexPath.row != myGeofences.count) return YES;
    return NO;
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [myGeofences removeObjectAtIndex:indexPath.row];

        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */


@end
