//
//  GMDataPuller.m
//  GluoseMonitor
//
//  Created by Michael Toth on 4/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GMDataPuller.h"
#import "Reading.h"

@implementation GMDataPuller 

@synthesize symbol;
@synthesize startDate;
@synthesize endDate;
@synthesize targetStartDate;
@synthesize targetEndDate;
@synthesize targetSymbol;
@synthesize overallLow;
@synthesize overallHigh;
@synthesize loadingData;
@synthesize glucoseData;

-(id)delegate
{
    return delegate;
}

-(void)setDelegate:(id)aDelegate
{
    delegate = aDelegate;
}

-(NSArray *)glucoseData
{
	//NSLog(@"in -financialData, returned financialData = %@", financialData);
    
	return glucoseData;
}

-(id)init
{
	NSTimeInterval secondsAgo = -timeIntervalForNumberOfWeeks(14.0f); //12 weeks ago
	NSDate *start			  = [NSDate dateWithTimeIntervalSinceNow:secondsAgo];
    
	NSDate *end = [NSDate date];
    
	NSDictionary *cachedDictionary = [self dictionaryForSymbol:@"level"];
        
	NSMutableDictionary *rep = [NSMutableDictionary dictionaryWithCapacity:7];
	[rep setObject:@"mg/dL" forKey:@"symbol"];
    Reading *firstReading = [self.glucoseData objectAtIndex:0];
    NSDate *firstDate = firstReading.timeStamp;
	[rep setObject:firstDate forKey:@"startDate"];
	[rep setObject:[NSDate date] forKey:@"endDate"];
	[rep setObject:[NSDecimalNumber notANumber] forKey:@"overallHigh"];
	[rep setObject:[NSDecimalNumber notANumber] forKey:@"overallLow"];
	[rep setObject:[NSArray array] forKey:@"glucoseData"];
	return [self initWithDictionary:rep targetSymbol:aSymbol targetStartDate:aStartDate targetEndDate:anEndDate];
}

-(id)initWithDictionary:(NSDictionary *)aDict targetSymbol:(NSString *)aSymbol targetStartDate:(NSDate *)aStartDate targetEndDate:(NSDate *)anEndDate
{
	self = [super init];
	if ( self != nil ) {
		self.symbol		   = [aDict objectForKey:@"symbol"];
		self.startDate	   = [aDict objectForKey:@"startDate"];
		self.overallLow	   = [NSDecimalNumber decimalNumberWithDecimal:[[aDict objectForKey:@"overallLow"] decimalValue]];
		self.overallHigh   = [NSDecimalNumber decimalNumberWithDecimal:[[aDict objectForKey:@"overallHigh"] decimalValue]];
		self.endDate	   = [aDict objectForKey:@"endDate"];
		self.financialData = [aDict objectForKey:@"financalData"];
        
		self.targetSymbol	 = aSymbol;
		self.targetStartDate = aStartDate;
		self.targetEndDate	 = anEndDate;
	}
	return self;
}

-(NSDictionary *)dictionaryForSymbol:(NSString *)aSymbol
{
	NSString *path						= [self faultTolerantPathForSymbol:aSymbol];
	NSMutableDictionary *localPlistDict = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    
	return localPlistDict;
}

@end

