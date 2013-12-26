//
//  geofencedPlace.m
//  Clockator
//
//  Created by Sabrina Ren on 12/25/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//
#import <AddressBookUI/AddressBookUI.h>
#import "geofencedPlace.h"


@implementation geofencedPlace
@synthesize fenceName, fenceIcon, fenceRadius, fencePlacemark, fenceRegion;

- (NSString *) fenceAddress {
    NSDictionary *addressDictionary = [self.fencePlacemark addressDictionary];
    return ABCreateStringWithAddressDictionary(addressDictionary, NO);
}

@end
