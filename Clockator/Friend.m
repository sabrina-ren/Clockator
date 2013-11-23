//
//  Friend.m
//  Clockator
//
//  Created by Sabrina Ren on 11/22/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import "Friend.h"
#import "AppDelegate.h"

@implementation Friend
@synthesize friendID, locationID, name, picture;

-(id)initWithID:(NSString *)newFriendID locationID:(NSString *)newLocID name:(NSString *)newName picture:(UIImage *)newpicture {
    if ((self=[super init])) {
        self.friendID = newFriendID;
        self.locationID = newLocID;
        self.name = newName;
        self.picture = newpicture;
    }
    return self;
}

+(void)getInitialData:(NSString *)dbPath {
    sqlite3 *database;
    NSLog(@"getting dbPath");
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    if (sqlite3_open([dbPath UTF8String], &database)==SQLITE_OK) {
        NSLog(@"opened");
        
        const char *sql = "SELECT friendID, locationID, name, picture FROM friend";
        
        sqlite3_stmt *selectstmt;
        if (sqlite3_prepare_v2(database,sql,-1,&selectstmt, NULL)==SQLITE_OK) {
            NSLog(@"prepared");
            while(sqlite3_step(selectstmt)==SQLITE_ROW) {
                NSString *primaryKey = [NSString stringWithUTF8String:(char*)sqlite3_column_text(selectstmt, 0)];
                NSString *locationID = [NSString stringWithUTF8String:(char*)sqlite3_column_text(selectstmt, 1)];
                NSString *name = [NSString stringWithUTF8String:(char*)sqlite3_column_text(selectstmt, 2)];
                NSData *pictureData = [[NSData alloc] initWithBytes:sqlite3_column_blob(selectstmt,3) length:sqlite3_column_bytes(selectstmt,3)];
                UIImage *picture = [UIImage imageWithData:pictureData];
                
                Friend *newFriend = [[Friend alloc] initWithID:primaryKey locationID:locationID name:name picture:picture];
                
                [appDelegate.friends addObject:newFriend];
                
                for (int i=0; i<[appDelegate.locations count]; i++) {
                    if ([locationID isEqualToString:[appDelegate.locations[i] locationID]]) {
                        [[appDelegate.friendsAtLocation objectAtIndex:i] addObject:newFriend];
                        break;
                    }
                }
            }
        } NSLog(@"Database returned error %d:%s", sqlite3_errcode(database), sqlite3_errmsg(database));
        sqlite3_finalize(selectstmt);
    }
    else sqlite3_close(database);
    
}

@end
