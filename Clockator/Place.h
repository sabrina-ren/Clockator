//
//  Place.h
//  Clockator
//
//  Created by Sabrina Ren on 12/24/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Place : NSObject

@property (nonatomic) NSString *placeName;
@property (nonatomic) UIImage *placeIcon;
@property (nonatomic) BOOL isShown;
@property (nonatomic) NSString *placeAddress;

+ (NSMutableArray *)getDefaultPlaces;

- (id)initWithName:(NSString *)newName icon:(UIImage *)newIcon;

@end
