//
//  Place.h
//  Clockator
//
//  Created by Sabrina Ren on 12/24/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CKPlace : NSObject

@property (nonatomic) NSString *placeName;
@property (nonatomic) UIImage *placeIcon;
@property (nonatomic) NSInteger placeIndex;
@property (nonatomic) BOOL isShown;

+ (NSMutableArray *)getDefaultPlaces;

- (id)initWithName:(NSString *)newName icon:(UIImage *)newIcon;

@end
