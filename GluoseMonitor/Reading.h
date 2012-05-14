//
//  Reading.h
//  GluoseMonitor
//
//  Created by Michael Toth on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Reading : NSManagedObject

@property (nonatomic, retain) NSNumber * fastingHours;
@property (nonatomic, retain) NSNumber * level;
@property (nonatomic, retain) NSDate * timeStamp;
@property (nonatomic, retain) NSString * notes;

@end
