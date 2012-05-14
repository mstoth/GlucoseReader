//
//  DisplayView.m
//  ECGraphic
//
//  Created by ris on 10-4-17.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DisplayView.h"
#import "ECCommon.h"
#import "ECGraphPoint.h"
#import "ECGraphLine.h"
#import "ECGraphItem.h"
#import "Reading.h"
#import "GMAppDelegate.h"

@implementation DisplayView
@synthesize readings;


- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        NSError *error = nil;
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSManagedObjectContext *context = [(GMAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
        
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Reading" inManagedObjectContext:context];
        [fetchRequest setEntity:entity];
        //fetchRequest.predicate = [NSPredicate predicateWithFormat:@"timeStamp = %@", lesson.date];
        readings = [context executeFetchRequest:fetchRequest error:&error];
        
    }
    return self;
}

- (IBAction)updateGraph {
    NSError *error = nil;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSManagedObjectContext *aContext = [(GMAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Reading" inManagedObjectContext:aContext];
    [fetchRequest setEntity:entity];
    //fetchRequest.predicate = [NSPredicate predicateWithFormat:@"timeStamp = %@", lesson.date];
    readings = [aContext executeFetchRequest:fetchRequest error:&error];
    
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    ECGraphPoint *p;
	CGContextRef _context = UIGraphicsGetCurrentContext();
	ECGraph *graph = [[ECGraph alloc] initWithFrame:CGRectMake(10,120, 267, 210) withContext:_context isPortrait:NO];
	
    NSMutableArray *pointsArray = [[NSMutableArray alloc] init];
    for (Reading *r in [self readings]) {
        NSDate *xDateValue = r.timeStamp;
        int yValue = [r.level intValue];
        p = [[ECGraphPoint alloc] init];
        p.xDateValue = xDateValue;
        p.yValue = yValue;
        [pointsArray addObject:p];
    }
    
	NSArray *points1 = pointsArray;
		
    ECGraphLine *line1 = [[ECGraphLine alloc] init];
	line1.isXDate = YES;
	line1.points = points1;
	line1.color = [UIColor blackColor];
	
	NSArray *lines = [[NSArray alloc] initWithObjects:line1,nil];

	[graph setXaxisTitle:@"Date"];
	[graph setYaxisTitle:@"Glucose Level"];
	[graph setGraphicTitle:@"Glucose Level in mg/dL"];
	[graph setXaxisDateFormat:@"MM/dd/YY"];
	[graph setDelegate:self];
	[graph setBackgroundColor:[UIColor colorWithRed:220/255.0 green:220/255.0 blue:220/255.0 alpha:1]];
	[graph setPointType:ECGraphPointTypeSquare];
    //[graph drawLineWithPoints:points1 lineWidth:2 color:[UIColor blackColor]];
	[graph drawCurveWithLines:lines lineWidth:2 color:[UIColor blackColor]];
	
	//ECGraphItem *item1 = [[ECGraphItem alloc] init];
//	item1.isPercentage = YES;
//	item1.yValue = 80;
//	item1.width = 35;
//	item1.name = @"item1";
//	
//	ECGraphItem *item2 = [[ECGraphItem alloc] init];
//	item2.isPercentage = YES;
//	item2.yValue = 35.3;
//	item2.width = 35;
//	item2.name = @"item2";
//	
//	ECGraphItem *item3 = [[ECGraphItem alloc] init];
//	item3.isPercentage = YES;
//	item3.yValue = 45;
//	item3.width = 35;
//	item3.name = @"item3";
//	
//	ECGraphItem *item4 = [[ECGraphItem alloc] init];
//	item4.isPercentage = YES;
//	item4.yValue = 78.6;
//	item4.width = 35;
//	item4.name = @"item4";
//	
//	ECGraphItem *item5 = [[ECGraphItem alloc] init];
//	item5.isPercentage = YES;
//	item5.yValue = 94.45;
//	item5.width = 35;
//	item5.name = @"item5";
//	
//	NSArray *items = [[NSArray alloc] initWithObjects:item1,item2,item3,item4,item5,nil];
//	[graph setXaxisTitle:@"name"];
//	[graph setYaxisTitle:@"Percentage"];
//	[graph setGraphicTitle:@"Histogram"];
//	[graph setDelegate:self];
//	[graph setBackgroundColor:[UIColor colorWithRed:220/255.0 green:220/255.0 blue:220/255.0 alpha:1]];
//	[graph drawHistogramWithItems:items lineWidth:2 color:[UIColor blackColor]];
	
}


- (void)dealloc {
    //[super dealloc];
}


@end
