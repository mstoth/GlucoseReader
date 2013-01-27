//
//  Reading.m
//  GluoseMonitor
//
//  Created by Michael Toth on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Reading.h"


@implementation Reading

@dynamic fastingHours;
@dynamic level;
@dynamic timeStamp;
@dynamic notes;

- (NSComparisonResult)compare:(Reading *)otherObject {
    return [self.timeStamp compare:otherObject.timeStamp];
}


-(NSInteger)timeOfDay {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    NSString *t = [dateFormatter stringFromDate:self.timeStamp];
    NSArray *hms = [t componentsSeparatedByString:@":"];
    NSInteger tod = [[hms objectAtIndex:0] intValue] * 60 * 60;
    tod += [[hms objectAtIndex:1] intValue] * 60;
    tod += [[hms objectAtIndex:2] intValue];
    return tod/60/60;
}

- (NSComparisonResult)compareTimeOfDay:(Reading *)otherObject {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    NSString *d1 = [dateFormatter stringFromDate:self.timeStamp];
    NSString *d2 = [dateFormatter stringFromDate:otherObject.timeStamp];
    return [d1 compare:d2];
}

@end
