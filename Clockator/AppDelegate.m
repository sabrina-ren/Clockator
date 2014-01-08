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
@property (nonatomic) NSString *userDisplayName;
@end

@implementation AppDelegate
@synthesize clockController,loginController;
@synthesize  managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Parse setApplicationId:parseApplicationId clientKey:parseClientKey];
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    [PFFacebookUtils initializeFacebook];
    
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setBarTintColor:[UIColor customSalmon]];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    clockController = [storyboard instantiateViewControllerWithIdentifier:@"ClockViewController"];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:clockController];
    self.window.rootViewController = navController;
    [self.window makeKeyAndVisible];
    
    if (!([PFUser currentUser] && [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]])) {
        // New user
        [self presentLoginControllerAnimated:NO];
    }
    else {
        // Signed in, refresh data
        [self refreshBasicFacebookData];
        [self refreshFacebookFriends];
        [self checkForAcceptedFriends];
    };
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logUserOut) name:CKNotificationShouldLogOut object:nil];
    
    return YES;
}

- (void)presentLoginControllerAnimated:(BOOL)animated {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    loginController = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
    loginController.delegate = self;
    loginController.isReachable = clockController.isReachable;
    [clockController presentViewController:loginController animated:animated completion:nil];
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

- (void)logUserOut {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:CKUserPreferencesClockFace];
    
    [PFUser logOut];
    [clockController.navigationController popToRootViewControllerAnimated:NO];
    [self presentLoginControllerAnimated:YES];
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
            self.userDisplayName = userData[@"name"];
            
            [[PFUser currentUser] setObject:facebookID forKey:@"fbID"];
            [[PFUser currentUser] setObject:self.userDisplayName forKey:@"displayName"];
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
    if ([PFUser currentUser]) {
        [[PFUser currentUser] setObject:self.imageData forKey:@"profilePicture"];
        [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (error) NSLog(@"image save error: %@", error);
            if (succeeded) NSLog(@"succeeded: %i", succeeded);
        }];
    }
    [loginController displayUserInfo:self.imageData forUser:self.userDisplayName];
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

#pragma mark - LoginViewController protocol method

- (void)didLoginUserIsNew:(BOOL)isNew {
    [self refreshBasicFacebookData];
    [self refreshFacebookFriends];
    [self checkForAcceptedFriends];
}
- (void)shouldDismissLoginController {
    clockController.shouldRefreshClock = YES;
    [clockController dismissViewControllerAnimated:YES completion:nil];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        }
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Clockator" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Clockator.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end