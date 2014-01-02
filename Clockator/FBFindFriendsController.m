//
//  FBFindFriendsController.m
//  Clockator
//
//  Created by Sabrina Ren on 12/21/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import "FBFindFriendsController.h"

@interface FBFindFriendsController ()

@property (retain, nonatomic) FBFriendPickerViewController *friendPickerController;
@property (retain, nonatomic) NSMutableArray *userList;

@end

@implementation FBFindFriendsController
@synthesize userList;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.delegate = self;
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 10, 40)];
    [titleLabel setTextColor:[UIColor whiteColor]];
    [titleLabel setText:@"Find Friends"];
    self.navigationItem.titleView = titleLabel;
    
    NSLog(@"user count: %i", userList.count);
    [self updateView];
//    NSArray *userObjects = [friendQuery findObjects];
//    for (PFUser *user in userObjects) {
//        [userList addObject:user[@"fbID"]];
//        NSLog(@"%@", [userList lastObject]);
//    }
}

- (void)preloadFriends {
    NSLog(@"Load data");
    PFQuery *friendQuery = [PFUser query];
    [friendQuery whereKeyExists:@"fbID"];
    [friendQuery findObjectsInBackgroundWithBlock:^(NSArray *users, NSError *error) {
        if (!error) {
            NSLog(@"Successfully retrieved %d users", users.count);
            userList = [NSMutableArray arrayWithCapacity:users.count];
            
            for (PFObject *user in users) {
                NSLog(@"%@", user[@"fbID"]);
                [userList addObject:user[@"fbID"]];
            }
        } else {
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)friendPickerViewController:(FBFriendPickerViewController *)friendPicker shouldIncludeUser:(id<FBGraphUser>)user {

    NSString *facebookId = user.id;
    NSLog(@"%@", facebookId);
    
    if ([userList containsObject:facebookId]) {
        NSLog(@"include user");
        return YES;
    }
    return NO;

}

- (void)facebookViewControllerCancelWasPressed:(id)sender {
    NSLog(@"cancelled");
    [self handlePickerDone];
}

- (void)facebookViewControllerDoneWasPressed:(id)sender {
    for (id<FBGraphUser> user in self.selection) {
        NSLog(@"Friend selected: %@", user.name);
    }
    [self handlePickerDone];
}

- (void)handlePickerDone {
//    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
