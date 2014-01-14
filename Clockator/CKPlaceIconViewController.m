//
//  PlaceIconViewController.m
//  Clockator
//
//  Created by Sabrina Ren on 12/24/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import "CKPlaceIconViewController.h"
#import "CKAppConstants.h"
#import "CKPlace.h"
#import "UIColor+CKColours.h"

@implementation CKPlaceIconViewController
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
    [titleLabel setFont:[UIFont fontWithName:@"DistrictPro-Thin" size:25]];
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
    CKPlace *thisPlace = clockPlaces[cellSwitch.tag];
    thisPlace.isShown = cellSwitch.on;
    
    [self.delegate didChangeClockFace];
    NSLog(@"%i", thisPlace.isShown);
    
    NSMutableArray *shownPreferences = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:CKUserPreferencesClockFace]];
    [shownPreferences replaceObjectAtIndex:cellSwitch.tag withObject:[NSNumber numberWithBool:thisPlace.isShown]];

    [[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithArray:shownPreferences] forKey:CKUserPreferencesClockFace];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (isIconView) return clockPlaces.count - 1;
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
        [cellSwitch setOnTintColor:[UIColor customLightSalmon]];
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
