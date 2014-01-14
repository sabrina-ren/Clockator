//
//  Location.h
//  Clockator
//
//  Created by Sabrina Ren on 11/22/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sqlite3.h"

@interface Location : NSObject

@property (nonatomic, copy) NSString* locationID;
@property (nonatomic, copy) NSString* locationName;
@property (nonatomic) BOOL isShown;
@property (nonatomic, copy) NSString* myAddress;
@property (nonatomic, copy) UIImage* iconPicture;

+ (void)getInitialData:(NSString*)dbPath;

- (id)initWithID:(NSString*)locationID locationName:(NSString*)locationName isShown:(BOOL)isShown myAddress:(NSString*)myAddress icon:(UIImage*)icon;

@end
