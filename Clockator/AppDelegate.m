//
//  AppDelegate.m
//  Clockator
//
//  Created by Sabrina Ren on 11/22/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import "AppDelegate.h"
#import "Location.h"
#import "Friend.h"
#import "UIColor+customColours.h"
#import <Parse/Parse.h>
#import "AppKeys.h"

@implementation AppDelegate
@synthesize databaseName, databasePath,locations, friends, friendsAtLocation;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    [Parse setApplicationId:parseApplicationId clientKey:parseClientKey];
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    [PFFacebookUtils initializeFacebook];
    
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];

    [[UINavigationBar appearance] setBarTintColor:[UIColor customTurquoise]];

    [self copyDatabaseIfNeeded];
    databasePath = [[NSBundle mainBundle] pathForResource:@"Clockator" ofType:@"sqlite"];
    
    NSMutableArray *tempArray = [[NSMutableArray alloc]init];
    locations = tempArray;
    NSMutableArray *tempArray1 = [[NSMutableArray alloc]init];
    friends = tempArray1;
    friendsAtLocation = [[NSMutableArray alloc] init];
    
    [Location getInitialData:databasePath];
    [Friend getInitialData:databasePath];
    
   
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [PFFacebookUtils handleOpenURL:url];
}


- (NSString*) getDBPath {
    databasePath = [[NSBundle mainBundle] pathForResource:@"Clockator" ofType:@"sqlite"];
    return databasePath;
}

- (void)copyDatabaseIfNeeded {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSString* dbPath = [self getDBPath];
    BOOL success = [fileManager fileExistsAtPath:dbPath];
    
    if (!success) {
        NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath]
                                   stringByAppendingPathComponent:@"Clockator.sqlite"];
        success = [fileManager copyItemAtPath:defaultDBPath toPath:dbPath error:&error];
        if (!success) NSAssert1(0,@"Failed to create writable database file with message '%@'.",[error localizedDescription]);
    }
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


@end
