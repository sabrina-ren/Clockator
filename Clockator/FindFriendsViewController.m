//
//  FindFriendsViewController.m
//  Clockator
//
//  Created by Sabrina Ren on 12/20/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import "FindFriendsViewController.h"

@interface FindFriendsViewController ()

@end

@implementation FindFriendsViewController

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
}
//
//- (NSArray *)findFriends {
//    
//    [FBRequestConnection startForMyFriendsWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
//        if (!error) {
//            // Result contains array with user's friends in 'data' key
//            NSArray *friendObjects = [result objectForKey:@"data"];
//            
//        }
//    }]
//    
//    // Issue a Facebook Graph API request to get your user's friend list
//    [FBRequestConnection startForMyFriendsWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
//        if (!error) {
//            // result will contain an array with your user's friends in the "data" key
//            NSArray *friendObjects = [result objectForKey:@"data"];
//            NSMutableArray *friendIds = [NSMutableArray arrayWithCapacity:friendObjects.count];
//            // Create a list of friends' Facebook IDs
//            for (NSDictionary *friendObject in friendObjects) {
//                [friendIds addObject:[friendObject objectForKey:@"id"]];
//            }
//            
//            // Construct a PFUser query that will find friends whose facebook ids
//            // are contained in the current user's friend list.
//            PFQuery *friendQuery = [PFUser query];
//            [friendQuery whereKey:@"fbId" containedIn:friendIds];
//            
//            // findObjects will return a list of PFUsers that are friends
//            // with the current user
//            NSArray *friendUsers = [friendQuery findObjects];
//        }
//    }];
//}

//- (PFQuery *)queryForTable {
//    //
//    
//}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
