//
//  Geofence.m
//  Clockator
//
//  Created by Sabrina Ren on 1/3/2014.
//  Copyright (c) 2014 Sabrina Ren. All rights reserved.
//

#import "Geofence.h"
#import <AddressBookUI/AddressBookUI.h>


@implementation Geofence

@dynamic fenceRegion;
@dynamic fencePlacemark;
@dynamic fenceName;
@dynamic iconIndex;
@dynamic fenceRadius;

- (NSString *) fenceAddress {
    NSDictionary *addressDictionary = [self.fencePlacemark addressDictionary];
    return ABCreateStringWithAddressDictionary(addressDictionary, NO);
}


@end
