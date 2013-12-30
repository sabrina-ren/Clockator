//
//  GeofencePlace.m
//  Clockator
//
//  Created by Sabrina Ren on 12/25/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//
#import "GeofencePlace.h"
#import <AddressBookUI/AddressBookUI.h>

@implementation GeofencePlace
@synthesize fenceName, iconIndex, fenceIcon, fenceRadius, fencePlacemark, fenceRegion;

- (NSString *) fenceAddress {
    NSDictionary *addressDictionary = [self.fencePlacemark addressDictionary];
    return ABCreateStringWithAddressDictionary(addressDictionary, NO);
}

@end
