//
//  ClockFaceSettingsControllerViewController.m
//  Clockator
//
//  Created by Sabrina Ren on 12/24/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import "ClockFaceSettingsController.h"
#import "Place.h"
#import "UIColor+customColours.h"
@interface ClockFaceSettingsController ()

@end

@implementation ClockFaceSettingsController
@synthesize clockPlaces;
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

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 15, 44)];
    [titleLabel setTextColor:[UIColor whiteColor]];
    [titleLabel setText:@"Clock Face"];
    self.navigationItem.titleView = titleLabel;
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return clockPlaces.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    cell.textLabel.text = [clockPlaces[indexPath.row] placeName];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UIImageView *imgV = [[UIImageView alloc] initWithFrame:CGRectMake(10, 7, 40, 30)];
    imgV.backgroundColor = [UIColor clearColor];
    [imgV.layer setMasksToBounds:YES];
    [imgV setImage:[clockPlaces[indexPath.row] placeIcon]];
    [cell.contentView addSubview:imgV];

    cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    UISwitch *cellSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
    cell.accessoryView = cellSwitch;
    cellSwitch.tag = indexPath.row;
    [cellSwitch setOn:[clockPlaces[indexPath.row] isShown] animated:NO];
    [cellSwitch setOnTintColor:[UIColor customLightBlue]];
    [cellSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    
    return cell;
}

- (IBAction)switchChanged:(id)sender {
    UISwitch *cellSwitch = sender;
    Place *thisPlace = clockPlaces[cellSwitch.tag];
    thisPlace.isShown = cellSwitch.on;
    NSLog(@"%i", thisPlace.isShown);
//    NSLog(@"Cell %i is %@", cellSwitch.tag, cellSwitch.on ? @"ON":@"OFF");
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

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
