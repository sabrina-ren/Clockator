//
//  FindFriendsViewController.m
//  Clockator
//
//  Created by Sabrina Ren on 12/20/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import "FindFriendsViewController.h"
#import "KeyConstants.h"

@interface FindFriendsViewController ()

@property (nonatomic) NSMutableDictionary *sections;
@property (nonatomic) NSMutableDictionary *sectionToFriendTypeMap;
@property (nonatomic) NSMutableArray *friendRequesters;
@property (nonatomic) NSMutableArray *friendRequestObjects;
@property (nonatomic) NSMutableArray *friends;

@end

@implementation FindFriendsViewController
@synthesize sections, sectionToFriendTypeMap, friendRequesters, friendRequestObjects, friends;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.pullToRefreshEnabled = YES;
        self.paginationEnabled = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.sections = [NSMutableDictionary dictionary];
    self.sectionToFriendTypeMap = [NSMutableDictionary dictionary];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 20, 40)];
    [titleLabel setFont:[UIFont fontWithName:@"DistrictPro-Thin" size:25]];
    [titleLabel setTextColor:[UIColor whiteColor]];
    [titleLabel setText:@"Friends"];
    self.navigationItem.titleView = titleLabel;
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (PFQuery *)queryForTable {
    PFQuery *friendQuery = [PFUser query];
    
    // Use cached data if none loaded
    if (!self.friendIds) self.friendIds = [[NSUserDefaults standardUserDefaults] objectForKey:@"friendIds"];
    [friendQuery whereKey:@"fbID" containedIn:self.friendIds];
    
    return friendQuery;
}

#pragma mark - Table view

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
//    NSLog(@"Cell for row at index");

    PFTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        NSLog(@"no cell");
        cell = [[PFTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    PFUser *user = (PFUser *)object;
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = user[@"displayName"];
    
    // Set picture
    NSData *imageData = user[@"profilePicture"];
    UIImageView *imgV = [[UIImageView alloc] initWithFrame:CGRectMake(10, 7, 40, 40)];
    imgV.backgroundColor = [UIColor clearColor];
    imgV.layer.cornerRadius = 20;
    imgV.layer.masksToBounds = YES;
    [imgV setImage: [UIImage imageWithData:imageData]];
    [cell.contentView addSubview:imgV];
    cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    NSString *friendType = [self friendTypeForSection:indexPath.section];

    if (![friendType isEqualToString:@"Friends"]) {
        // Set button
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 45, 45)];
        [button setImage:[UIImage imageNamed:@"Add.png"] forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:@"AddSelected.png"] forState:UIControlStateSelected];
        button.tag = indexPath.row;
        if ([friendType isEqualToString:@"None"])
            [button addTarget:self action:@selector(shouldToggleFriendButton:) forControlEvents:UIControlEventTouchUpInside];
        else [button addTarget:self action:@selector(shouldAcceptFriend:) forControlEvents:UIControlEventTouchUpInside];
        cell.accessoryView = button;
        
        if ([friendType isEqualToString:@"None"]) {
            PFQuery *pendingQuery = [PFQuery queryWithClassName:@"FriendRequest"];
            [pendingQuery whereKey:@"fromUser" equalTo:[PFUser currentUser]];
            [pendingQuery whereKey:@"toUser" equalTo:object];
            [pendingQuery whereKey:@"status" equalTo:@"pending"];
            [pendingQuery countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
                if (!error && number>0) {
                    NSLog(@"set selected\n\n");
                    [button setSelected: YES];
                    CABasicAnimation *rotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
                    rotation.duration = 0.1;
                    rotation.cumulative = NO;
                    rotation.fillMode = kCAFillModeForwards;
                    rotation.removedOnCompletion = NO;
                    rotation.toValue = [NSNumber numberWithFloat:M_PI/4];
                    [button.layer setAnchorPoint:CGPointMake(0.5, 0.5)];
                    [button.layer addAnimation:rotation forKey:@"rotation"];
                }
            }];
        }
    }
    else cell.accessoryView = nil;
    return cell;
}

- (NSString *)friendTypeForSection:(NSInteger)section {
    return [sectionToFriendTypeMap objectForKey:[NSNumber numberWithInteger:section]];
}

- (void)objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    
    [self.sections removeAllObjects]; // Index of all objects in sections
    [self.sectionToFriendTypeMap removeAllObjects];
    
    

//
//    NSLog(@"friends count:%i", friends.count);
//
    
    friendRequesters = [[NSMutableArray alloc] init]; // Users
    friendRequestObjects = [[NSMutableArray alloc] init]; // FriendRequest objects
    
    // Get pending friend requests sent to current user
    PFQuery *requestedQuery = [PFQuery queryWithClassName:@"FriendRequest"];
    [requestedQuery whereKey:@"toUser" equalTo:[PFUser currentUser]];
    [requestedQuery whereKey:@"status" equalTo:@"pending"];
    [requestedQuery includeKey:@"fromUser"];
    [requestedQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        for (PFObject *object in objects) {
            PFUser *user = object[@"fromUser"];
            [friendRequesters addObject:user.objectId];
            [friendRequestObjects addObject:object];
        }

        // Get list of friends
        friends = [[PFUser currentUser] objectForKey:CKUserFriendsKey];
        if (!friends) friends = [[NSMutableArray alloc] init];
        
        int requestSectionExists = 0;
        int friendsSectionExists = 0;
        if (friendRequesters.count > 0) requestSectionExists = 1;
        if (friends.count > 0) friendsSectionExists = 1;
        
        int section;
        NSInteger rowIndex = 0;
        for (PFObject *object in self.objects) {
            NSString *friendType;
            if ([friendRequesters containsObject:object.objectId]) {
                friendType = @"Requests";
                section = 0;
            }
            else if ([friends containsObject:object.objectId]) {
                friendType = @"Friends";
                section = requestSectionExists;
            }
            else {
                friendType = @"None";
                section = requestSectionExists + friendsSectionExists;
            }
            NSMutableArray *objectsInSection = [sections objectForKey:friendType];
            if (!objectsInSection) {
                objectsInSection = [NSMutableArray array]; // New section
                [sectionToFriendTypeMap setObject:friendType forKey:[NSNumber numberWithInt:section]];
            }
            [objectsInSection addObject:[NSNumber numberWithInteger:rowIndex++]];
            [sections setObject:objectsInSection forKey:friendType];
        }
        [self.tableView reloadData];
    }];
}

- (PFObject *)objectAtIndexPath:(NSIndexPath *)indexPath {
    NSString *friendType = [self friendTypeForSection:indexPath.section];
    NSArray *rowIndicesInSection = [sections objectForKey:friendType];
    NSNumber *rowIndex = [rowIndicesInSection objectAtIndex:indexPath.row];
    return [self.objects objectAtIndex:[rowIndex intValue]];
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSLog(@"Number of sections: %i", sections.allKeys.count);
    return sections.allKeys.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString *friendType = [self friendTypeForSection:section];
    NSArray *rowIndicesInSection = [sections objectForKey:friendType];
    return rowIndicesInSection.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *friendType = [self friendTypeForSection:section];
    if ([friendType isEqualToString:@"None"]) return nil;
    return friendType;
}

#pragma mark - Friend request

- (void)shouldAcceptFriend:(id)sender {
    UIButton *button = (UIButton *)sender;
    [button setSelected:YES];
    
    NSInteger buttonIndex = button.tag;
    NSArray *rowIndicesInSection = [sections objectForKey:@"Requests"];
    int index = [[rowIndicesInSection objectAtIndex:buttonIndex] intValue];
    PFUser *newFriend = (PFUser *) self.objects[index];
    
    NSLog(@"Accept friend: %@", newFriend[CKUserDisplayNameKey]);

    PFObject *friendRequest;
    int requestIndex = 0;
    for (PFObject *request in friendRequestObjects) {
        PFUser *fromUser = [request objectForKey:CKFriendReqFromUserKey];
        if ([newFriend.objectId isEqualToString:fromUser.objectId]) {
            friendRequest = request;
            break;
        }
        requestIndex++;
    }
    NSLog(@"Accept request: %@", friendRequest.objectId);
    [friendRequestObjects removeObject:friendRequest];
    [friendRequesters removeObject:newFriend];
    
    [friendRequest setObject:@"accepted" forKey:CKFriendReqStatusKey];
    [friendRequest saveEventually];

    [friends addObject:newFriend.objectId];
    [[PFUser currentUser] setObject:friends forKey:CKUserFriendsKey];
    [[PFUser currentUser] saveEventually:^(BOOL succeeded, NSError *error) {
        
        // Remote notification
//        NSString *privateChannelName = [newFriend objectForKey:CKUserPrivateChannelKey];
//        if (privateChannelName && privateChannelName.length > 0) {
//            NSString *userName = [[PFUser currentUser] objectForKey:CKUserDisplayNameKey];
//            NSString *message = [NSString stringWithFormat:@"%@ accepted your friend request", userName];
//            NSDictionary *payload = [NSDictionary dictionaryWithObjectsAndKeys:message, CKAPNSAlertKey, @"accepted", CKPayloadTypeKey, [PFUser currentUser].objectId, CKPayloadFromUserKey, nil];
//            
//            PFPush *push = [[PFPush alloc] init];
//            [push setChannel:privateChannelName];
//            [push setData:payload];
//            [push sendPushInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
//                NSLog(@"Remote push notification succeeded: %i", succeeded);
//                if (error) NSLog(@"Error: %@", error);
//            }];
//        }
        
        [self loadObjects];
        [self.tableView reloadData];
    }];
}

- (void)shouldToggleFriendButton:(id)sender {
    UIButton *button = (UIButton *)sender;
    [button setSelected:!button.selected];
    
    NSInteger buttonIndex = button.tag;
    NSArray *rowIndicesInSection = [sections objectForKey:@"None"];
    int index = [[rowIndicesInSection objectAtIndex:buttonIndex] intValue];
    PFUser *user = (PFUser *) self.objects[index];

    NSLog(@"name: %@", user[@"displayName"]);
    
    CABasicAnimation *rotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotation.duration = 0.3;
    rotation.cumulative = NO;
    rotation.fillMode = kCAFillModeForwards;
    rotation.removedOnCompletion = NO;
    NSNumber *angle = [NSNumber numberWithFloat:M_PI/4];
    
    if (!button.selected) {
        NSLog(@"Unfollow");
        rotation.fromValue = angle;
        rotation.toValue = [NSNumber numberWithFloat:0];
        [self cancelFriendRequestTo:user];
    }
    else {
        NSLog(@"Follow");
        rotation.toValue = angle;
        [self sendFriendRequestTo:user block:^(BOOL succeeded, NSError *error) {
            NSLog(@"Send friend request succeeded: %i", succeeded);
            if (error)NSLog(@"Send friend request error: %@", error);
        }];
    }
    [button.layer setAnchorPoint:CGPointMake(0.5, 0.5)];
    [button.layer addAnimation:rotation forKey:@"rotation"];
}

- (void)sendFriendRequestTo:(PFUser *)user block:(void(^)(BOOL succeeded, NSError *error))completionBlock {
    PFObject *friendRequest = [PFObject objectWithClassName:CKFriendReqClass];
    [friendRequest setObject:[PFUser currentUser] forKey:CKFriendReqFromUserKey];
    [friendRequest setObject:user forKey:CKFriendReqToUserKey];
    [friendRequest setObject:@"pending" forKey:CKFriendReqStatusKey];

    PFACL *acl = [PFACL ACL];
    [acl setPublicReadAccess:YES];
    [acl setPublicWriteAccess:NO];
    [acl setWriteAccess:YES forUser:user];
    [acl setWriteAccess:YES forUser:[PFUser currentUser]];
    
    friendRequest.ACL = acl;
    [friendRequest saveEventually:completionBlock];
}

- (void)cancelFriendRequestTo:(PFUser *)user {
    PFQuery *pendingQuery = [PFQuery queryWithClassName:CKFriendReqClass];
    [pendingQuery whereKey:CKFriendReqFromUserKey equalTo:[PFUser currentUser]];
    [pendingQuery whereKey:CKFriendReqToUserKey equalTo:user];
    [pendingQuery whereKey:@"status" equalTo:@"pending"];
    [pendingQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            for (PFObject *object in objects)  {
                [object deleteEventually];
            }
        }
        else NSLog(@"Cancel request error: %@", error);
    }];
}

@end
