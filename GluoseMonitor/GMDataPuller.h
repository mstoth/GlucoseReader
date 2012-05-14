//
//  GMDataPuller.h
//  GluoseMonitor
//
//  Created by Michael Toth on 4/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GMDataPuller : NSObject {
    NSString *symbol;
	NSDate *startDate;
	NSDate *endDate;
    
	NSDate *targetStartDate;
	NSDate *targetEndDate;
	NSString *targetSymbol;
    
	id delegate;
	NSDecimalNumber *overallHigh;
	NSDecimalNumber *overallLow;
	BOOL loadingData;
	BOOL staleData;
    
@private
	NSArray *glucoseData; // consists of dictionaries
    
	NSMutableData *receivedData;
	NSURLConnection *connection;

}
@property (nonatomic, readonly, retain) NSArray *glucoseData;
@property (nonatomic, assign) id delegate;
@property (nonatomic, copy) NSString *symbol;
@property (nonatomic, retain) NSDate *startDate;
@property (nonatomic, retain) NSDate *endDate;
@property (nonatomic, copy) NSString *targetSymbol;
@property (nonatomic, retain) NSDate *targetStartDate;
@property (nonatomic, retain) NSDate *targetEndDate;
@property (nonatomic, readonly, retain) NSDecimalNumber *overallHigh;
@property (nonatomic, readonly, retain) NSDecimalNumber *overallLow;
@property (nonatomic, readonly, assign) BOOL loadingData;


@end


