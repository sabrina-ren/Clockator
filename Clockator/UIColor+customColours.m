//
//  UIColor+customColours.m
//  Clockator
//
//  Created by Sabrina Ren on 12/24/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import "UIColor+customColours.h"

@implementation UIColor (customColours)

+ (UIColor *)customSalmon {
    return [UIColor colorWithHue:0.0/360.0 saturation:0.7 brightness:0.85 alpha:1];
}

+ (UIColor *)customLightSalmon {
    return [UIColor colorWithHue:2.0/360.0 saturation:0.7 brightness:0.95 alpha:1];
}

+ (UIColor *)customTransparentSalmon {
    return [UIColor colorWithHue:0 saturation:0.7 brightness:0.85 alpha:0.8];
}

+ (UIColor *)customTransparentBlack {
    return [UIColor colorWithHue:0 saturation:0 brightness:0 alpha:0.3];
}

+ (UIColor *)customTransparentMapSalmon {
    return [UIColor colorWithHue:2.0/360.0 saturation:0.8 brightness:1 alpha:0.5];
}


@end
