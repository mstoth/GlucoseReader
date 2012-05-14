//
//  gsllib.h
//  gsllib
//
//  Created by Michael Toth on 4/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
//#include "vector/gsl_vector.h"

@interface gsllib : NSObject

//- (NSArray *)getCubicCoefficients:(NSArray *)values num:(int)n;
- (NSArray *)getParams:(NSArray *)values num:(int)n;
@end
