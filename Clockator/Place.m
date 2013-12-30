//
//  Place.m
//  Clockator
//
//  Created by Sabrina Ren on 12/24/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import "Place.h"

@implementation Place

@synthesize placeName, placeIcon, placeIndex, isShown;

+ (NSMutableArray *)getDefaultPlaces {
    NSArray *names = @[@"Bar", @"Home", @"Other", @"School", @"Work"];
    
    NSMutableArray *defaultPlaces = [[NSMutableArray alloc] init];
    
    for (int i=0; i<names.count; i++) {
        Place *newPlace = [[Place alloc] initWithName:names[i] icon:[UIImage imageNamed:[names[i] stringByAppendingPathExtension:@"png"]]];
        newPlace.placeIndex = i;
        [defaultPlaces addObject:newPlace];
    }
    return defaultPlaces;
}

- (id)initWithName:(NSString *)newName icon:(UIImage *)newIcon {
    if (self = [super init]) {
        self.placeName = newName;
        self.placeIcon = newIcon;
        self.isShown = YES;
    }
    return self;
    
}

@end
