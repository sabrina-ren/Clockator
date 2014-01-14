//
//  Friend.h
//  Clockator
//
//  Created by Sabrina Ren on 11/22/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface Friend : NSObject

@property (nonatomic, assign) NSString *friendID;
@property (nonatomic, copy) NSString *locationID;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) UIImage *picture;

+ (void)getInitialData:(NSString*)dbPath;

- (id)initWithID:(NSString*)friendID locationID:(NSString*)newLocID name:(NSString*)newName picture:(UIImage*)newPicture;

@end
