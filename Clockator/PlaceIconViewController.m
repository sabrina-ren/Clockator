//
//  PlaceIconViewController.m
//  Clockator
//
//  Created by Sabrina Ren on 12/24/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import "PlaceIconViewController.h"
#import "Place.h"
#import "UIColor+customColours.h"

@implementation PlaceIconViewController
@synthesize clockPlaces, isIconView, currentIconIndex;
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
    if (isIconView)[titleLabel setText:@"Choose Icon"];
    else [titleLabel setText:@"Clock Face"];
    
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

#pragma mark - UI Behaviour

- (IBAction)switchChanged:(id)sender {
    UISwitch *cellSwitch = sender;
    Place *thisPlace = clockPlaces[cellSwitch.tag];
    thisPlace.isShown = cellSwitch.on;
    NSLog(@"%i", thisPlace.isShown);
    //    NSLog(@"Cell %i is %@", cellSwitch.tag, cellSwitch.on ? @"ON":@"OFF");
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
    if (!isIconView) cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UIImageView *imgV = [[UIImageView alloc] initWithFrame:CGRectMake(10, 7, 40, 30)];
    imgV.backgroundColor = [UIColor clearColor];
    [imgV.layer setMasksToBounds:YES];
    [imgV setImage:[clockPlaces[indexPath.row] placeIcon]];
    [cell.contentView addSubview:imgV];

    cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    if (currentIconIndex == indexPath.row && isIconView) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else if (!isIconView) {
        UISwitch *cellSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        cell.accessoryView = cellSwitch;
        cellSwitch.tag = indexPath.row;
        [cellSwitch setOn:[clockPlaces[indexPath.row] isShown] animated:NO];
        [cellSwitch setOnTintColor:[UIColor customLightBlue]];
        [cellSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (isIconView) {
        [self.delegate placeIconController:self didChangeIconIndex:indexPath.row];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
