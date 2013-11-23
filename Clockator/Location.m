//
//  Location.m
//  Clockator
//
//  Created by Sabrina Ren on 11/22/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import "Location.h"
#import "AppDelegate.h"
#import "Location.h"

@implementation Location

@synthesize locationID, locationName, myAddress, iconPicture;

- (id) initWithID:(NSString *)newID locationName:(NSString *)newName isShown:(BOOL)isShown myAddress:(NSString *)newAddress icon:(UIImage*)newPicture {
    if ((self=[super init])) {
        self.locationID = newID;
        self.locationName = newName;
        self.isShown = isShown;
        self.myAddress = newAddress;
        self.iconPicture = newPicture;
    }
    return self;
}

+ (void)getInitialData:(NSString *)dbPath {
    sqlite3 *database;
    NSLog(@"getting dbPath");
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    if (sqlite3_open([dbPath UTF8String], &database)==SQLITE_OK) {
        NSLog(@"opened");
        
        const char *sql = "SELECT locationID, locationName, isShown, myAddress, iconPicture FROM location";
        
        sqlite3_stmt *selectstmt;
        if (sqlite3_prepare_v2(database,sql,-1,&selectstmt, NULL)==SQLITE_OK) {
            NSLog(@"prepared");
            while(sqlite3_step(selectstmt)==SQLITE_ROW) {
                NSString *primaryKey = [NSString stringWithUTF8String:(char*)sqlite3_column_text(selectstmt, 0)];
                NSString *name = [NSString stringWithUTF8String:(char*)sqlite3_column_text(selectstmt, 1)];
                NSLog(@"name %@", name);
                BOOL isShown = sqlite3_column_int(selectstmt,2);
                NSString *address = [NSString stringWithUTF8String:(char*)sqlite3_column_text(selectstmt, 3)];
                NSData *pictureData = [[NSData alloc] initWithBytes:sqlite3_column_blob(selectstmt,4) length:sqlite3_column_bytes(selectstmt,4)];
                UIImage *picture = [UIImage imageWithData:pictureData];
                Location *locationObj = [[Location alloc] initWithID:primaryKey locationName:name isShown:isShown myAddress:address icon:picture];
                
                [appDelegate.locations addObject:locationObj];
                [appDelegate.friendsAtLocation addObject:[[NSMutableArray alloc] init]];
            }
        } NSLog(@"Database returned error %d:%s", sqlite3_errcode(database), sqlite3_errmsg(database));
        sqlite3_finalize(selectstmt);
    }
    else sqlite3_close(database);
    
    
}


@end