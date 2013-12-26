//
//  geofencedPlace.h
//  Clockator
//
//  Created by Sabrina Ren on 12/25/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>


@interface geofencedPlace : NSObject

@property (nonatomic) CLPlacemark *fencePlacemark;
@property (nonatomic) CLCircularRegion *fenceRegion;

@property (nonatomic) NSString *fenceName;
@property (nonatomic) UIImage *fenceIcon;

@property CGFloat fenceRadius;

- (NSString *) fenceAddress;

@end
