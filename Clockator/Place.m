//
//  Place.m
//  Clockator
//
//  Created by Sabrina Ren on 12/24/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import "Place.h"
#import "KeyConstants.h"

@implementation Place

@synthesize placeName, placeIcon, placeIndex, isShown;

+ (NSMutableArray *)getDefaultPlaces {
    NSArray *shownPreferences = [[NSUserDefaults standardUserDefaults] arrayForKey:CKUserPreferencesClockFace];
    if (!shownPreferences) {
        NSLog(@"No shown preferences");
        shownPreferences = @[@1,@1,@1,@1,@1];
        [[NSUserDefaults standardUserDefaults] setObject:shownPreferences forKey:CKUserPreferencesClockFace];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    NSArray *names = @[@"Bar", @"Home", @"School", @"Work", @"Other"];
    
    NSMutableArray *defaultPlaces = [[NSMutableArray alloc] init];

    for (int i=0; i<names.count; i++) {
        Place *newPlace = [[Place alloc] initWithName:names[i] icon:[UIImage imageNamed:[names[i] stringByAppendingPathExtension:@"png"]]];
        newPlace.placeIndex = i;
        
        newPlace.isShown = [shownPreferences[i] boolValue];
        [defaultPlaces addObject:newPlace];
    }
    return defaultPlaces;
}

- (id)initWithName:(NSString *)newName icon:(UIImage *)newIcon {
    if (self = [super init]) {
        self.placeName = newName;
        self.placeIcon = newIcon;
    }
    return self;
}

@end
