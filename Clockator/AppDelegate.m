//
//  AppDelegate.m
//  Clockator
//
//  Created by Sabrina Ren on 11/22/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import "AppDelegate.h"
#import "AppKeys.h"
#import "ClockViewController.h"
#import "KeyConstants.h"
#import "UIColor+customColours.h"
#import <Parse/Parse.h>


@interface AppDelegate() 

@property (nonatomic) ClockViewController *clockController;
@property (nonatomic) LoginViewController *loginController;

@property (nonatomic) NSMutableData *imageData;

@end

@implementation AppDelegate
@synthesize clockController,loginController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Parse setApplicationId:parseApplicationId clientKey:parseClientKey];
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    [PFFacebookUtils initializeFacebook];
    
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setBarTintColor:[UIColor customTurquoise]];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    clockController = [storyboard instantiateViewControllerWithIdentifier:@"ClockViewController"];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:clockController];
    self.window.rootViewController = navController;
    [self.window makeKeyAndVisible];
    
    loginController = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
    loginController.delegate = self;
    
    if (!([PFUser currentUser] && [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]])) {
        // New user
        [clockController presentViewController:loginController animated:NO completion:nil];
    }
    else {
        // Signed in, refresh data
        [self refreshBasicFacebookData];
        [self refreshFacebookFriends];
        [self checkForAcceptedFriends];
    };
    
    // Remote notifications
//    [self handlePush:launchOptions];
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [FBSession.activeSession handleDidBecomeActive];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [FBSession.activeSession close];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [PFFacebookUtils handleOpenURL:url];
}

#pragma mark - Retrieve Facebook data

- (void)refreshFacebookFriends {
    [FBRequestConnection startForMyFriendsWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            // Result contains array with user's friends in 'data' key
            NSArray *friendObjects = [result objectForKey:@"data"];
            NSMutableArray *friendIds = [NSMutableArray arrayWithCapacity:friendObjects.count];
            
            // Create list of friends' Facebook IDs
            for (NSDictionary *friendObject in friendObjects) {
                [friendIds addObject:friendObject[@"id"]];
            }

            [[NSUserDefaults standardUserDefaults] setObject:friendIds forKey:@"friendIds"];
            [[NSUserDefaults standardUserDefaults] synchronize];

            NSLog(@"facebook id: %@", [[PFUser currentUser] objectForKey:@"fbID"]);
            NSLog(@"Friend id count: %lu", (unsigned long)friendIds.count);
            clockController.friendIds = friendIds;
        }
    }];
}

- (void)refreshBasicFacebookData {
    // Create request for user's Facebook data
    FBRequest *request = [FBRequest requestForMe];
    
    // Send request to Facebook
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            NSDictionary *userData = (NSDictionary *)result;
            
            NSString *facebookID = userData[@"id"];
            NSString *name = userData[@"name"];
            
            [[PFUser currentUser] setObject:facebookID forKey:@"fbID"];
            [[PFUser currentUser] setObject:name forKey:@"displayName"];
            [[PFUser currentUser] saveInBackground];
            
            //            userNameLabel.text = name;
            self.imageData = [[NSMutableData alloc] init];

            NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?width=100&height=100", facebookID]];
            
            NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:imageURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:2.0f];
            // Run network request asynchronously
            NSURLConnection *urlConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
        }
        else if ([error.userInfo[FBErrorParsedJSONResponseKey][@"body"][@"error"][@"type"] isEqualToString:@"OAuthException"]) { // Since the request failed, we can check if it was due to an invalid session
            NSLog(@"The facebook session was invalidated");
            [clockController presentViewController:loginController animated:NO completion:nil];
        }
        else {
            NSLog(@"Some other error: %@", error);
        }
    }];
}

// Called everytime piece of data is received
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.imageData appendData:data];
}

// Called when entire image is finished downloading
- (void)connectionDidFinishLoading:(NSURLConnection*)connection {
    NSLog(@"saved profile picture");
    [[PFUser currentUser] setObject:self.imageData forKey:@"profilePicture"];
    [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error) NSLog(@"image save error: %@", error);
        if (succeeded) NSLog(@"succeeded: %i", succeeded);
    }];
}

#pragma mark - Refresh Parse data

- (void)checkForAcceptedFriends {
    // Find accepted friend requests
    PFQuery *query = [PFQuery queryWithClassName:CKFriendReqClass];
    [query whereKey:CKFriendReqFromUserKey equalTo:[PFUser currentUser]];
    [query whereKey:CKFriendReqStatusKey equalTo:@"accepted"];
    [query includeKey:CKFriendReqToUserKey];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        NSMutableArray *friends = [[PFUser currentUser] objectForKey:CKUserFriendsKey];
        if (!friends) friends = [[NSMutableArray alloc] init];
        
        for (PFObject *object in objects) {
            // Add to friends array
            PFUser *newFriend = [object objectForKey:CKFriendReqToUserKey];
            [friends addObject:newFriend.objectId];
            [[PFUser currentUser] setObject:friends forKey:CKUserFriendsKey];
            
            // Change status to added
            [object setObject:@"added" forKey:CKFriendReqStatusKey];
            [object saveEventually];
        }
        [[PFUser currentUser] saveEventually];
    }];
}

#pragma mark - Remote Notifications

//- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
//    [PFPush storeDeviceToken:deviceToken];
//    [[PFInstallation currentInstallation] addUniqueObject:@"" forKey:CKInstallationChannelsKey];
//    [[PFInstallation currentInstallation] saveEventually];
//    
//    
//    if ([PFUser currentUser]) {
//        NSString *privateChannelName = [[PFUser currentUser] objectForKey:CKUserPrivateChannelKey];
//        if (privateChannelName && privateChannelName.length > 0) {
//            NSLog(@"Subscribing user to %@", privateChannelName);
//            [[PFInstallation currentInstallation] addUniqueObject:privateChannelName forKey:CKInstallationChannelsKey];
//        }
//    }
//    [[PFInstallation currentInstallation] saveEventually];
//}
//
//- (void)handlePush:(NSDictionary *)launchOptions {
//    NSDictionary *payload = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
//    if (payload && [PFUser currentUser]) {
//        PFUser *fromFriend = [payload objectForKey:CKPayloadFromUserKey];
//        NSString *type = [payload objectForKey:CKPayloadTypeKey];
//        if ([type isEqualToString:@"accepted"]) {
//            // Add to own friends list
//            NSMutableArray *friends = [[PFUser currentUser] objectForKey:CKUserFriendsKey];
//            if (!friends || friends.count == 0) friends = [[NSMutableArray alloc] init];
//            [friends addObject:fromFriend.objectId];
//            [[PFUser currentUser] setObject:friends forKey:CKUserFriendsKey];
//        }
//    }
//}

#pragma mark - LoginViewController protocol method

- (void)didLoginUserIsNew:(BOOL)isNew {
    [clockController dismissViewControllerAnimated:YES completion:nil];
    [self refreshBasicFacebookData];
    [self refreshFacebookFriends];
    [self checkForAcceptedFriends];
    
    // Subscribe to private push channel
//    if ([PFUser currentUser]) {
//        NSString *privateChannelName = [NSString stringWithFormat:@"user_%@", [PFUser currentUser].objectId];
//        [[PFInstallation currentInstallation] setObject:[PFUser currentUser] forKey:CKInstallationUserKey];
//        [[PFInstallation currentInstallation] saveEventually];
//        [[PFUser currentUser] setObject:privateChannelName forKey:CKUserPrivateChannelKey];
//    }
}

@end
