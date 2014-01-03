//
//  CKFriend.m
//  Clockator
//
//  Created by Sabrina Ren on 1/2/2014.
//  Copyright (c) 2014 Sabrina Ren. All rights reserved.
//

#import "CKFriend.h"

@implementation CKFriend

- (NSString *)locationUpdatedAt {
    if (!self.updatedAt) return @"";
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:[NSLocale currentLocale]];
    
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
    NSDateComponents *components = [calendar components:unitFlags fromDate:self.updatedAt toDate:[NSDate date] options:1];
    
    NSString *dateString;
    if ([components day] > 0) {
        [formatter setDateStyle:NSDateFormatterMediumStyle];
        [formatter setTimeStyle:NSDateFormatterNoStyle];
        dateString = @"on ";
    }
    else {
        [formatter setDateStyle:NSDateFormatterNoStyle];
        [formatter setTimeStyle:NSDateFormatterShortStyle];
        dateString = @"at ";
    }
    dateString = [dateString stringByAppendingString:[formatter stringFromDate:self.updatedAt]];
    return dateString;
}

@end
