//
//  AppDelegate.h
//  Clockator
//
//  Created by Sabrina Ren on 11/22/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <sqlite3.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic) NSString *databaseName;
@property (nonatomic) NSString *databasePath;
@property (nonatomic, retain) NSMutableArray *locations;
@property (nonatomic, retain) NSMutableArray *friends;
@property (nonatomic, retain) NSMutableArray *friendsAtLocation;
-(void) copyDatabaseIfNeeded;
-(NSString*) getDBPath;

@end
