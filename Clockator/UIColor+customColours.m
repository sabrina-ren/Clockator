//
//  UIColor+customColours.m
//  Clockator
//
//  Created by Sabrina Ren on 12/24/2013.
//  Copyright (c) 2013 Sabrina Ren. All rights reserved.
//

#import "UIColor+customColours.h"

@implementation UIColor (customColours)

+ (UIColor *)customTurquoise {
    return [UIColor colorWithHue:220.0/360.0 saturation:1.0 brightness:0.54 alpha:1];
}

+ (UIColor *)customLightBlue {
    return [UIColor colorWithHue:185.0/360.0 saturation:0.56 brightness:0.84 alpha:1];
}

+ (UIColor *)customTransparentTurquoise {
    return [UIColor colorWithHue:185.0/360.0 saturation:0.56 brightness:0.84 alpha:0.5];
}

+ (UIColor *)customCoral {
    return [UIColor colorWithHue:4.0/360.0 saturation:0.7 brightness:0.85 alpha:1];
}

+ (UIColor *)customOrange{
    return [UIColor colorWithHue:30.0/360.0 saturation:0.69 brightness:0.94 alpha:1];
}



@end
