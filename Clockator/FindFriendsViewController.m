//
//  FindFriendsViewController.m
//  Clockator
//
//  Created by Sabrina Ren on 12/20/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import "FindFriendsViewController.h"

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
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (PFQuery *)queryForTable {
    NSLog(@"query for table");
    PFQuery *friendQuery = [PFUser query];
    
    // Use cached data if none loaded
    if (!self.friendIds) self.friendIds = [[NSUserDefaults standardUserDefaults] objectForKey:@"friendIds"];
    [friendQuery whereKey:@"fbID" containedIn:self.friendIds];
    
    return friendQuery;
}

#pragma mark - Table view

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {

    PFTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        NSLog(@"no cell");
        cell = [[PFTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    PFUser *user = (PFUser *)object;
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = user[@"displayName"];
    NSLog(@"name: %@", user[@"displayName"]);
    
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
    NSLog(@"\n\nFriend type: %@", friendType);

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
    
//    friends = [[NSMutableArray alloc] init];
//    friends = [NSMutableArray arrayWithArray:[PFUser currentUser][@"friends"]];
//
//    NSLog(@"friends count:%i", friends.count);
//    
    NSLog(@"querying friend types");
    
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
        NSLog(@"requested friend count: %i", objects.count);

        // Get list of friends
        friends = [[NSMutableArray alloc] init];
        friends = [NSMutableArray arrayWithArray:[PFUser currentUser][@"friends"]];
        NSLog(@"friends count:%i", friends.count);
        
        NSInteger requestSectionExists = 0;
        NSInteger friendsSectionExists = 0;
        if (friendRequesters.count > 0) requestSectionExists = 1;
        if (friends.count > 0) friendsSectionExists = 1;
        
        NSInteger section;
        NSInteger rowIndex = 0;
        for (PFObject *object in self.objects) {
            NSLog(@"Object number: %i id: %@", rowIndex, object.objectId);
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
            NSLog(@"Friend type: %@", friendType);
            NSMutableArray *objectsInSection = [sections objectForKey:friendType];
            if (!objectsInSection) {
                objectsInSection = [NSMutableArray array]; // New section
                [sectionToFriendTypeMap setObject:friendType forKey:[NSNumber numberWithInt:section]];
            }
            [objectsInSection addObject:[NSNumber numberWithInt:rowIndex++]];
            [sections setObject:objectsInSection forKey:friendType];
            NSLog(@"Objects num: %i in section: %i for type:%@\n", objectsInSection.count, section, friendType);
        }
        [self.tableView reloadData];
    }];
}

- (PFObject *)objectAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Object at indexpath\n\n");
    NSString *friendType = [self friendTypeForSection:indexPath.section];
    NSArray *rowIndicesInSection = [sections objectForKey:friendType];
    NSNumber *rowIndex = [rowIndicesInSection objectAtIndex:indexPath.row];
    return [self.objects objectAtIndex:[rowIndex intValue]];
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSLog(@"number of sections: %i", sections.allKeys.count);
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
    NSInteger index = button.tag;
    PFObject *friendRequest = friendRequestObjects[index];
    [friendRequest setObject:@"accepted" forKey:@"status"];
    [friends addObject:friendRequesters[index]];
    [[PFUser currentUser] setObject:friends forKey:@"friends"];
    
    [friendRequest saveEventually];
    [[PFUser currentUser] saveEventually];
    
    [friendRequestObjects removeObjectAtIndex:index];
    [friendRequesters removeObjectAtIndex:index];

    [self loadObjects];
    [self.tableView reloadData];
    // Need to send notification for user to also add to friends list
}

- (void)shouldToggleFriendButton:(id)sender {
    UIButton *button = (UIButton *)sender;
    [button setSelected:!button.selected];
    
    NSInteger index = ((UIButton *) sender).tag;
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
    }
    else {
        NSLog(@"Follow");
        rotation.toValue = angle;
    }
    [button.layer setAnchorPoint:CGPointMake(0.5, 0.5)];
    [button.layer addAnimation:rotation forKey:@"rotation"];
    
}

- (void)sendFriendRequestTo:(PFUser *)user block:(void(^)(BOOL succeeded, NSError *error))completionBlock {
    
    PFObject *friendRequest = [PFObject objectWithClassName:@"FriendRequest"];
    [friendRequest setObject:[PFUser currentUser] forKey:@"fromUser"];
    [friendRequest setObject:user forKey:@"toUser"];
    [friendRequest setObject:@"pending" forKey:@"status"];
    
    PFACL *acl = [PFACL ACL];
    [acl setPublicReadAccess:YES];
    [acl setPublicWriteAccess:NO];
    [acl setWriteAccess:YES forUser:user];
    [acl setWriteAccess:YES forUser:[PFUser currentUser]];
    
    friendRequest.ACL = acl;
    [friendRequest saveEventually];
}

@end
