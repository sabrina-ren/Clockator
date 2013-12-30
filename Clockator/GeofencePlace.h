//
//  GeofencePlace.h
//  Clockator
//
//  Created by Sabrina Ren on 12/25/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

@interface GeofencePlace : NSObject

@property (nonatomic) CLPlacemark *fencePlacemark;
@property (nonatomic) CLCircularRegion *fenceRegion;

@property (nonatomic) NSString *fenceName;
@property (nonatomic) UIImage *fenceIcon;

@property NSInteger iconIndex;
@property CGFloat fenceRadius;

- (NSString *) fenceAddress;

@end
