//
//  Geofence.h
//  Clockator
//
//  Created by Sabrina Ren on 1/3/2014.
//  Copyright (c) 2014 Sabrina Ren. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <CoreLocation/CoreLocation.h>


@interface Geofence : NSManagedObject

@property (nonatomic) CLCircularRegion *fenceRegion;
@property (nonatomic) CLPlacemark *fencePlacemark;
@property (nonatomic) NSString *fenceName;
@property (nonatomic) NSInteger iconIndex;
@property CGFloat fenceRadius;

- (NSString *) fenceAddress;


@end
