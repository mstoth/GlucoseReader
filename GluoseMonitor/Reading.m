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

@end
