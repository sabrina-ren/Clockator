//
//  Place.m
//  Clockator
//
//  Created by Sabrina Ren on 12/24/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import "CKPlace.h"
#import "CKAppConstants.h"

@implementation CKPlace

@synthesize placeName, placeIcon, placeIndex, isShown;

+ (NSMutableArray *)getDefaultPlaces {
    NSArray *shownPreferences = [[NSUserDefaults standardUserDefaults] arrayForKey:CKUserPreferencesClockFace];
    if (!shownPreferences) {
        NSLog(@"No shown preferences");
        shownPreferences = @[@0,@1,@1,@1,@1,@1];
        [[NSUserDefaults standardUserDefaults] setObject:shownPreferences forKey:CKUserPreferencesClockFace];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    NSArray *names = @[@"Bar", @"Cafe", @"Home", @"School", @"Work", @"Other"];
    
    NSMutableArray *defaultPlaces = [[NSMutableArray alloc] init];

    for (int i=0; i<names.count; i++) {
        CKPlace *newPlace = [[CKPlace alloc] initWithName:names[i] icon:[UIImage imageNamed:[names[i] stringByAppendingPathExtension:@"png"]]];
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
