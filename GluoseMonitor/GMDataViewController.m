//
//  GMDataViewController.m
//  GlucoseMonitor
//
//  Created by Michael Toth on 10/16/12.
//  Copyright (c) 2012 Michael Toth. All rights reserved.
//

#import "GMDataViewController.h"
#import "Reading.h"
#import "gsllib.h"
#include <math.h> 
#import "GMDetailViewController.h"
#import "GMDataViewController.h"
#import "CorePlot-CocoaTouch.h"
#import "DisplayView.h"

#include "gsl_vector.h"
#include "gsl_multifit.h"


@interface GMDataViewController ()
@property (weak, nonatomic) IBOutlet UISlider *upperSlider;
@property (weak, nonatomic) IBOutlet UISlider *lowerSlider;

@end

@implementation GMDataViewController

@synthesize earliestDateToPlot,latestDateToPlot;
@synthesize dataForPlot;
@synthesize bestFitDataForPlot;
@synthesize A,B,C,Go;
@synthesize plotXRange; // if this is 0, the range of the data is used.  If not 0, the length of time (in seconds) is the interpreted value.  i.e. 60*60*24*30 is one month. 
@synthesize graphDataView;
@synthesize lowerLabel;
@synthesize upperLabel;
@synthesize xAxisSegmentedControl;
@synthesize readings;
@synthesize graph;
@synthesize reading;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.plotXRange = 0; // use the range of the data
    self.earliestDateToPlot = [self getEarliestDate];
    self.latestDateToPlot = [self getLatestDate];
    [self setDateLabels];
    
    // set up graph
    // By default, FASTING is the mode for the graph.  This plots glucose vs fasting hours.
    self.xAxisSegmentedControl.selectedSegmentIndex = 1;
    [self createFastingPlot];
    

}
- (void)setUpGraph {
    self.graph = [[CPTXYGraph alloc] initWithFrame:CGRectZero];
	CPTTheme *theme = [CPTTheme themeNamed:kCPTDarkGradientTheme];
	[self.graph applyTheme:theme];
    
    self.graphDataView.hostedGraph = self.graph;
    
    self.graph.paddingLeft	= 10.0;
	self.graph.paddingTop	= 10.0;
	self.graph.paddingRight	= 10.0;
	self.graph.paddingBottom = 10.0;
}

- (void)createTimePlot {
    // set theme and padding of graph
    [self setUpGraph];
    
    
    // Setup plot space
	CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
    plotSpace.delegate = self;
	plotSpace.allowsUserInteraction = YES;
	plotSpace.xRange				= [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0) length:CPTDecimalFromFloat(24.0)];
	plotSpace.yRange				= [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(-0.2*[self maxLevel]) length:CPTDecimalFromDouble([self maxLevel]+85.0)];
    
    // Axes
	CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
    
    // x axis
	CPTXYAxis *x		  = axisSet.xAxis;
    x.title = @"Time of Day";
    x.titleOffset = -30;
	x.majorIntervalLength		  = CPTDecimalFromFloat(4); // divide x axis by hours which is 60*60 seconds
	x.orthogonalCoordinateDecimal = CPTDecimalFromFloat(0);
	x.minorTicksPerInterval		  = 0;
    
    // y axis
    CPTXYAxis *y = axisSet.yAxis;
	y.majorIntervalLength		  = CPTDecimalFromString(@"50");
	y.minorTicksPerInterval		  = 1;
	y.orthogonalCoordinateDecimal = CPTDecimalFromFloat(4);
	NSArray *exclusionRanges = [NSArray arrayWithObjects:[CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-1) length:CPTDecimalFromFloat(2)],nil];
	y.labelExclusionRanges = exclusionRanges;
	y.delegate			   = self;
    
    // Create a yellow plot area
	CPTScatterPlot *boundLinePlot  = [[CPTScatterPlot alloc] init];
	CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle lineStyle];
	lineStyle.miterLimit		= 1.0f;
	lineStyle.lineWidth			= 0.0f;
	lineStyle.lineColor			= [CPTColor yellowColor];
	boundLinePlot.dataLineStyle = lineStyle;
	boundLinePlot.identifier	= @"timeOfDay";
	boundLinePlot.dataSource	= self;
    boundLinePlot.frame = CGRectMake(46, 173, 208, 143);
    boundLinePlot.title = @"mg/dL";
    boundLinePlot.name = @"mg/dL";
    
    
    CPTMutableLineStyle *symbolLineStyle = [CPTMutableLineStyle lineStyle];
    symbolLineStyle.lineColor = [CPTColor yellowColor];
    CPTPlotSymbol *plotSymbol = [CPTPlotSymbol diamondPlotSymbol];
    plotSymbol.fill			 = [CPTFill fillWithColor:[CPTColor yellowColor]];
    plotSymbol.lineStyle	 = symbolLineStyle;
    plotSymbol.size			 = CGSizeMake(10.0, 10.0);
    boundLinePlot.plotSymbol = plotSymbol;
    
	[self.graph addPlot:boundLinePlot];
    

    // Add legend
    self.graph.legend = [CPTLegend legendWithPlots:[NSArray arrayWithObjects:boundLinePlot, nil]];
	self.graph.legend.textStyle		  = x.titleTextStyle;
	self.graph.legend.fill			  = [CPTFill fillWithColor:[CPTColor darkGrayColor]];
	self.graph.legend.borderLineStyle = x.axisLineStyle;
	self.graph.legend.cornerRadius	  = 5.0;
	self.graph.legend.swatchSize	  = CGSizeMake(25.0, 25.0);
	self.graph.legendAnchor			  = CPTRectAnchorTopRight;
	self.graph.legendDisplacement	  = CGPointMake(0, 0.0);
    
    NSMutableArray *displayedPoints = [self.readings mutableCopy];
	NSMutableArray *contentArray = [[NSMutableArray alloc] init];
    [displayedPoints sortUsingSelector:@selector(compareTimeOfDay:)];

	NSUInteger i;
	for ( i = 0; i < [displayedPoints count]; i++ ) {
        Reading *r = [displayedPoints objectAtIndex:i];
        if (self.lowerSlider.value == 0 && self.upperSlider.value == 1) {
            id x = r;
            id y = r.level;
            [contentArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:x, @"x", y, @"y", nil]];
        } else {
            if (([r.timeStamp timeIntervalSinceDate:self.earliestDateToPlot] > -3600) && ([r.timeStamp timeIntervalSinceDate:self.latestDateToPlot] < 3600))
            {
                id x = r;
                id y = r.level;
                [contentArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:x, @"x", y, @"y", nil]];
            }
        }
	}
    
	self.dataForPlot = contentArray;
        
    
    [self.graphDataView.hostedGraph reloadData];

}


- (void)createFastingPlot {
    
    // set theme and padding of graph
    [self setUpGraph];
    
    
    // Setup plot space
	CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
    plotSpace.delegate = self;
	plotSpace.allowsUserInteraction = YES;
	plotSpace.xRange				= [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-5.0) length:CPTDecimalFromFloat(24.0)];
	plotSpace.yRange				= [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(-0.2*[self maxLevel]) length:CPTDecimalFromDouble([self maxLevel]+85.0)];
    
    // Axes
    
	CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
	CPTXYAxis *x		  = axisSet.xAxis;
    x.title = @"Fasting Hours";
    x.titleOffset = -30;
	x.majorIntervalLength		  = CPTDecimalFromFloat(5.0);
	x.orthogonalCoordinateDecimal = CPTDecimalFromFloat(0);
	x.minorTicksPerInterval		  = 0;
    
    CPTXYAxis *y = axisSet.yAxis;
	y.majorIntervalLength		  = CPTDecimalFromString(@"50");
	y.minorTicksPerInterval		  = 1;
	y.orthogonalCoordinateDecimal = CPTDecimalFromFloat(0);
	NSArray *exclusionRanges = [NSArray arrayWithObjects:[CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-1) length:CPTDecimalFromFloat(2)],nil];
	y.labelExclusionRanges = exclusionRanges;
	y.delegate			   = self;
    
    // Create a yellow plot area
	CPTScatterPlot *boundLinePlot  = [[CPTScatterPlot alloc] init];
	CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle lineStyle];
	lineStyle.miterLimit		= 1.0f;
	lineStyle.lineWidth			= 0.0f;
	lineStyle.lineColor			= [CPTColor yellowColor];
	boundLinePlot.dataLineStyle = lineStyle;
	boundLinePlot.identifier	= @"vsHours";
	boundLinePlot.dataSource	= self;
    boundLinePlot.frame = CGRectMake(46, 173, 208, 143);
    boundLinePlot.title = @"mg/dL";
    boundLinePlot.name = @"mg/dL";
    
    
    CPTMutableLineStyle *symbolLineStyle = [CPTMutableLineStyle lineStyle];
    symbolLineStyle.lineColor = [CPTColor yellowColor];
    CPTPlotSymbol *plotSymbol = [CPTPlotSymbol diamondPlotSymbol];
    plotSymbol.fill			 = [CPTFill fillWithColor:[CPTColor yellowColor]];
    plotSymbol.lineStyle	 = symbolLineStyle;
    plotSymbol.size			 = CGSizeMake(10.0, 10.0);
    boundLinePlot.plotSymbol = plotSymbol;
    
	[self.graph addPlot:boundLinePlot];
    
    
    // Create the best fit line
    CPTScatterPlot *bestFitPlot = [[CPTScatterPlot alloc] init];
    CPTMutableLineStyle *bestFitLineStyle = [CPTMutableLineStyle lineStyle];
    bestFitLineStyle.miterLimit = 1.0f;
    bestFitLineStyle.lineWidth = 2.0f;
    bestFitLineStyle.lineColor = [CPTColor redColor];
    bestFitPlot.dataLineStyle = bestFitLineStyle;
    bestFitPlot.identifier = @"bestFit";
    bestFitPlot.dataSource = self;
    bestFitPlot.frame = CGRectMake(46,173,208,143);
    bestFitPlot.title = @"Best Fit";
    bestFitPlot.name = @"Best Fit";
    
    [self.graph addPlot:bestFitPlot];
    
    // Add legend
    if ([self.readings count]>=10)
        self.graph.legend = [CPTLegend legendWithPlots:[NSArray arrayWithObjects:boundLinePlot, bestFitPlot, nil]];
    else {
        self.graph.legend = [CPTLegend legendWithPlots:[NSArray arrayWithObjects:boundLinePlot, nil]];
    }
	self.graph.legend.textStyle		  = x.titleTextStyle;
	self.graph.legend.fill			  = [CPTFill fillWithColor:[CPTColor darkGrayColor]];
	self.graph.legend.borderLineStyle = x.axisLineStyle;
	self.graph.legend.cornerRadius	  = 5.0;
	self.graph.legend.swatchSize	  = CGSizeMake(25.0, 25.0);
	self.graph.legendAnchor			  = CPTRectAnchorTopRight;
	self.graph.legendDisplacement	  = CGPointMake(0, 0.0);
    
    NSMutableArray *displayedPoints = [self.readings mutableCopy];
	NSMutableArray *contentArray = [[NSMutableArray alloc] init];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:NO];
    [displayedPoints sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    NSDate *latestDate = [(Reading *)[displayedPoints objectAtIndex:0] timeStamp];
	NSUInteger i;
	for ( i = 0; i < [displayedPoints count]; i++ ) {
        Reading *r = [displayedPoints objectAtIndex:i];
        if (([r.timeStamp timeIntervalSinceDate:self.earliestDateToPlot] > -3600) && ([r.timeStamp timeIntervalSinceDate:self.latestDateToPlot] < 3600))
        {
            
            if (self.plotXRange > 0) {
                //NSLog(@"Date by adding time interval is %@",[latestDate dateByAddingTimeInterval:(0.0 - self.range)]);
                if ([r.timeStamp timeIntervalSinceDate:[latestDate dateByAddingTimeInterval:(0.0 - self.plotXRange)]] >= 0) {
                    id x = r.fastingHours;
                    id y = r.level;
                    [contentArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:x, @"x", y, @"y", nil]];
                } else {
                    // Don't add this item, it's out of range.
                }
            } else {
                id x = r.fastingHours;
                id y = r.level;
                [contentArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:x, @"x", y, @"y", nil]];
            }
        }
	}
    
    // arrays for holding the best fit results
    double bestFitX[120];
    double bestFitY[120];
    double bestFitW[120];
    
	self.dataForPlot = contentArray;
    int limit;		
    if ([contentArray count]>120) {
        limit=120;
    } else {
        limit=[contentArray count];
    }
    
    for (i=0; i< limit; i++) {
        bestFitX[i]=[[[contentArray objectAtIndex:i] objectForKey:@"x"] doubleValue];
        bestFitY[i]=[[[contentArray objectAtIndex:i] objectForKey:@"y"] doubleValue];
        bestFitW[i]=0.5; // all the same weight
    }
    
    NSArray *coefficients;
    gsllib *lib = [[gsllib alloc] init];
    if (limit > 6)
        coefficients = [lib getParams:contentArray num:limit];
    self.Go = [coefficients objectAtIndex:0];
    self.A = [coefficients objectAtIndex:1];
    self.B = [coefficients objectAtIndex:2];
    self.C = [coefficients objectAtIndex:3];
    self.bestFitDataForPlot = [[NSMutableArray alloc] init];
    
    double maxYval = 0;
    double filteredY[120];
    for (i=0;i<120;i++) {
        double xVal, yVal, term2p2;
        xVal=i/10.0;
        
        // f(x)=Go + A * e^(-B*x) * x^C
        double term2p1 = exp((-([self.B doubleValue]*xVal)));
        if (xVal == 0.0) {
            term2p2 = 0;
        } else {
            term2p2 = pow(xVal, [self.C doubleValue]);
        }
        
        yVal = [self.Go doubleValue] + ([self.A doubleValue] * term2p1 * term2p2);
        if (i==0) {
            filteredY[i]=yVal;
        } else {
            filteredY[i]=filteredY[i-1] + 0.8*(yVal - filteredY[i-1]);
        }
        yVal = filteredY[i];
        if (maxYval < yVal) {
            maxYval = yVal;
        }
		[self.bestFitDataForPlot addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:xVal], @"x", [NSNumber numberWithDouble:yVal], @"y", nil]];
    }
    if (limit>6) {
        [[self.graphDataView.hostedGraph plotSpaceAtIndex:0] 
         setPlotRange:[CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(-0.2*maxYval) 
                                                   length:CPTDecimalFromDouble(90+maxYval)] forCoordinate:CPTCoordinateY];
    }
    [self.graphDataView.hostedGraph reloadData];
    [contentArray removeAllObjects];
}

- (void)createDatePlot {
    Reading *lastReading,*firstReading;
    NSDate *referenceDate;
    NSTimeInterval xRange;
    NSMutableArray *displayedPoints = [[NSMutableArray alloc] init];
    if ([self.readings count]>0) {
        displayedPoints = [self.readings mutableCopy];
        NSArray  *sortedPoints = [displayedPoints sortedArrayUsingSelector:@selector(compare:)];
        displayedPoints = [sortedPoints mutableCopy];
        lastReading = [displayedPoints lastObject];
        firstReading = [displayedPoints objectAtIndex:0];
        //NSLog(@"%@",firstReading.description);
        xRange = [lastReading.timeStamp timeIntervalSinceDate:firstReading.timeStamp];
        referenceDate = self.reading.timeStamp;
        xRange = [lastReading.timeStamp timeIntervalSinceDate:firstReading.timeStamp];
        xRange = xRange;
    } else {
        return;
    }
    
    // Create graph from theme
	self.graph = [[CPTXYGraph alloc] initWithFrame:CGRectZero];
	CPTTheme *theme = [CPTTheme themeNamed:kCPTDarkGradientTheme];
	[self.graph applyTheme:theme];
    self.graphDataView.hostedGraph = self.graph;
    
	self.graph.paddingLeft	= 10.0;
	self.graph.paddingTop	= 10.0;
	self.graph.paddingRight	= 10.0;
	self.graph.paddingBottom = 10.0;
    
	// Setup plot space
	CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
    plotSpace.delegate=self;
	plotSpace.allowsUserInteraction = YES;
	//plotSpace.xRange				= [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-2*60*60*24) length:CPTDecimalFromFloat(4*60*60*24*7)];
	plotSpace.xRange				= [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-5*60*60*24) length:CPTDecimalFromFloat(10*60*60*24)];
	plotSpace.yRange				= [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(-0.2*[self maxLevel]) length:CPTDecimalFromDouble([self maxLevel]+45.0)];
    
    
	// Axes
	CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
	CPTXYAxis *x		  = axisSet.xAxis;
	x.majorIntervalLength		  = CPTDecimalFromFloat(60*60*24*2);
	x.orthogonalCoordinateDecimal = CPTDecimalFromFloat(0);
	x.minorTicksPerInterval		  = 3;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	dateFormatter.dateStyle = kCFDateFormatterShortStyle;
	CPTTimeFormatter *myDateFormatter = [[CPTTimeFormatter alloc] initWithDateFormatter:dateFormatter];
	myDateFormatter.referenceDate = self.reading.timeStamp;
	x.labelFormatter			  = myDateFormatter;
    
    NSDateFormatter *df = [NSDateFormatter new];
    [df setDateFormat:@"mm/dd/yyyy - hh:mma"];
    self.title = [df stringFromDate:[self.reading valueForKey:@"timeStamp"]];
    
	CPTXYAxis *y = axisSet.yAxis;
	y.majorIntervalLength		  = CPTDecimalFromString(@"25");
	y.minorTicksPerInterval		  = 1;
	y.orthogonalCoordinateDecimal = CPTDecimalFromFloat(0);
	NSArray *exclusionRanges = [NSArray arrayWithObjects:[CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-100) length:CPTDecimalFromFloat(101)],nil];
	y.labelExclusionRanges = exclusionRanges;
	y.delegate			   = self;
    
	// Create a yellow plot area
	CPTScatterPlot *boundLinePlot  = [[CPTScatterPlot alloc] init];
	CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle lineStyle];
	lineStyle.miterLimit		= 1.0f;
	lineStyle.lineWidth			= 1.0f;
	lineStyle.lineColor			= [CPTColor yellowColor];
	boundLinePlot.dataLineStyle = lineStyle;
	boundLinePlot.identifier	= @"vsTime";
	boundLinePlot.dataSource	= self;
    boundLinePlot.frame = CGRectMake(46, 173, 208, 143);
    boundLinePlot.title = @"mg/dL";
    boundLinePlot.name = @"mg/dL";
    
	[self.graph addPlot:boundLinePlot];
    
	// Do a yellow gradient
	CPTColor *areaColor1	   = [CPTColor colorWithComponentRed:0.9 green:0.9 blue:0.1 alpha:0.8];
	CPTGradient *areaGradient1 = [CPTGradient gradientWithBeginningColor:areaColor1 endingColor:[CPTColor clearColor]];
	areaGradient1.angle = -90.0f;
	CPTFill *areaGradientFill = [CPTFill fillWithGradient:areaGradient1];
	boundLinePlot.areaFill		= areaGradientFill;
	boundLinePlot.areaBaseValue = [[NSDecimalNumber zero] decimalValue];
    
	// Add plot symbols
	CPTMutableLineStyle *symbolLineStyle = [CPTMutableLineStyle lineStyle];
	symbolLineStyle.lineColor = [CPTColor yellowColor];
    
	// Create a green plot area
	CPTScatterPlot *dataSourceLinePlot = [[CPTScatterPlot alloc] init];
	lineStyle						 = [CPTMutableLineStyle lineStyle];
	lineStyle.lineWidth				 = 3.f;
	lineStyle.lineColor				 = [CPTColor greenColor];
	lineStyle.dashPattern			 = [NSArray arrayWithObjects:[NSNumber numberWithFloat:5.0f], [NSNumber numberWithFloat:5.0f], nil];
	dataSourceLinePlot.dataLineStyle = lineStyle;
	dataSourceLinePlot.identifier	 = @"Green Plot";
	dataSourceLinePlot.dataSource	 = self;
    dataSourceLinePlot.name = @"Hours (x10)";
    dataSourceLinePlot.title = @"Hours (x10)";
    
	// Put an area gradient under the plot above
	CPTColor *areaColor		  = [CPTColor colorWithComponentRed:0.3 green:1.0 blue:0.3 alpha:0.8];
	CPTGradient *areaGradient = [CPTGradient gradientWithBeginningColor:areaColor endingColor:[CPTColor clearColor]];
	areaGradient.angle				 = -90.0f;
	areaGradientFill				 = [CPTFill fillWithGradient:areaGradient];
	dataSourceLinePlot.areaFill		 = areaGradientFill;
	dataSourceLinePlot.areaBaseValue = CPTDecimalFromString(@"1.75");
    
    // Add legend
    self.graph.legend = [CPTLegend legendWithPlots:[NSArray arrayWithObjects:boundLinePlot,dataSourceLinePlot, nil]];
	self.graph.legend.textStyle		 = x.titleTextStyle;
	self.graph.legend.fill			 = [CPTFill fillWithColor:[CPTColor darkGrayColor]];
	self.graph.legend.borderLineStyle = x.axisLineStyle;
	self.graph.legend.cornerRadius	 = 5.0;
	self.graph.legend.swatchSize		 = CGSizeMake(25.0, 25.0);
	self.graph.legendAnchor			 = CPTRectAnchorTop;
	self.graph.legendDisplacement	 = CGPointMake(0, 0.0);
    
    
    // Animate in the new plot, as an example
	dataSourceLinePlot.opacity = 0.0f;
	[self.graph addPlot:dataSourceLinePlot];
    
	CABasicAnimation *fadeInAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
	fadeInAnimation.duration			= 1.0f;
	fadeInAnimation.removedOnCompletion = NO;
	fadeInAnimation.fillMode			= kCAFillModeForwards;
	fadeInAnimation.toValue				= [NSNumber numberWithFloat:1.0];
	[dataSourceLinePlot addAnimation:fadeInAnimation forKey:@"animateOpacity"];
    
	// Add some initial data
	NSMutableArray *contentArray = [NSMutableArray arrayWithCapacity:100];
	NSUInteger i;
	for ( i = 0; i < [self.readings count]; i++ ) {
        Reading *r = [self.readings objectAtIndex:i];
        if (([r.timeStamp timeIntervalSinceDate:self.earliestDateToPlot] > -3600.0) && ([r.timeStamp timeIntervalSinceDate:self.latestDateToPlot] < 3600))
        {
            NSTimeInterval seconds = [r.timeStamp timeIntervalSinceDate:referenceDate];
            NSNumber *n = [NSNumber numberWithDouble:seconds];
            float scaledHours = [r.fastingHours floatValue]*10;
            NSNumber *hours = [NSNumber numberWithFloat:scaledHours];
            id x = n;
            id y = r.level;
            id h = hours;
            [contentArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:x, @"x", y, @"y", h, @"h", nil]];
        }
    }
	self.dataForPlot = contentArray;
    [self.graphDataView.hostedGraph reloadData];
}


- (void)viewDidUnload
{
    [self setLowerLabel:nil];
    [self setUpperLabel:nil];
    [self setGraphDataView:nil];
    [self setXAxisSegmentedControl:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)lowerStepper:(id)sender {
}

- (IBAction)upperStepper:(id)sender {
}

- (void) setDateLabels {
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateStyle:NSDateFormatterMediumStyle];
    self.lowerLabel.text = [df stringFromDate:self.earliestDateToPlot];
    self.upperLabel.text = [df stringFromDate:self.latestDateToPlot];
}

- (void) setDateLimits {
    NSTimeInterval totalTime = [[self getLatestDate] timeIntervalSinceDate:[self getEarliestDate]];
    NSTimeInterval newLowTimeInterval = totalTime * (1-[self.lowerSlider value]);
    NSTimeInterval newHighTimeInterval = totalTime * [self.upperSlider value];
    NSDate *latest = [self getLatestDate];
    NSDate *earliest = [self getEarliestDate];
    self.earliestDateToPlot = [latest dateByAddingTimeInterval:-newLowTimeInterval];
    self.latestDateToPlot = [earliest dateByAddingTimeInterval:newHighTimeInterval];
    [self setDateLabels];
}

- (IBAction)lowerSlider:(id)sender {
    if ([[self lowerSlider] value] > [[self upperSlider] value]) {
        self.upperSlider.value = self.lowerSlider.value;
    }
    [self setDateLimits];
}

- (IBAction)upperSlider:(id)sender {
    if ([[self lowerSlider] value] > [[self upperSlider] value]) {
        self.lowerSlider.value = self.upperSlider.value;
    }
    [self setDateLimits];
}

- (IBAction)xAxisTypeChanged:(id)sender {
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    [self.activityIndicator startAnimating];

    dispatch_async(globalQueue, ^{
        [self updateGraph];
        dispatch_async(dispatch_get_main_queue(), ^{
           [self.activityIndicator stopAnimating];
        });
    });
}

- (void) updateGraph {
    [self.activityIndicator startAnimating];

    // 0 = Time of Day, 1 = fasting hours, 2 = Date (Chronological)
    NSInteger graphType = [self.xAxisSegmentedControl selectedSegmentIndex];
    switch (graphType) {
        case TIME_OF_DAY:
            // handle time of day 
            [self createTimePlot];
            break;
            
        case FASTING:
            // handle fasting
            [self createFastingPlot];
            break;
            
        case DATE:
            // handle date
            [self createDatePlot];
            break;
            
        default:
            break;
    }
    [self.activityIndicator stopAnimating];
}

#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    if ([(NSString *)plot.identifier isEqualToString:@"bestFit"]) {
        if ([dataForPlot count]<10) {
            return 0;
        }
        return 100;
    } else {
        return [dataForPlot count];
    }
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
	NSString *key = (fieldEnum == CPTScatterPlotFieldX ? @"x" : @"y");
    if ([(NSString *)plot.identifier isEqualToString:@"bestFit"]) {
        return [[self.bestFitDataForPlot objectAtIndex:index] valueForKey:key];
    }
    if ([(NSString *)plot.identifier isEqualToString:@"timeOfDay"]) {
        if ([key isEqualToString:@"x"]) {
            Reading *r = [[dataForPlot objectAtIndex:index] valueForKey:key];
            NSNumber *num = [NSNumber numberWithInteger:r.timeOfDay];
            return num;
        }
        if ([key isEqualToString:@"y"]) {
            NSNumber *num = [[dataForPlot objectAtIndex:index] valueForKey:key];
            return num;            
        }
    }
    if ( [(NSString *)plot.identifier isEqualToString:@"Green Plot"] ) {
        if ([key isEqualToString:@"y"]) 
            key=@"h";
    }
    NSNumber *num = [[self.dataForPlot objectAtIndex:index] valueForKey:key];
    //NSLog(@"Returning %f",[num floatValue]);
    return num;
}


#pragma mark - CPTLegendDelegate methods

- (BOOL) legend:(CPTLegend *)legend shouldDrawSwatchAtIndex:(NSUInteger)index forPlot:(CPTPlot *)plot inRect:(CGRect)rect inContext:(CGContextRef)context {
    return YES;
}


#pragma mark -
#pragma mark Plot Space Delegate Methods

-(CPTPlotRange *)plotSpace:(CPTPlotSpace *)space willChangePlotRangeTo:(CPTPlotRange *)newRange forCoordinate:(CPTCoordinate)coordinate
{
    if (self.xAxisSegmentedControl.selectedSegmentIndex == FASTING) {
        CPTXYPlotSpace * plot_space = (CPTXYPlotSpace*)space;
        plot_space.globalYRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(-0.2*[self maxLevel]) length:CPTDecimalFromDouble([self maxLevel]+85.0)];
        
        if (coordinate == CPTCoordinateX) {
            CPTXYAxisSet *newAxisSet = [[CPTXYAxisSet alloc] initWithFrame:self.graph.axisSet.frame];
            newAxisSet = (CPTXYAxisSet *) self.graph.axisSet;
            CPTXYAxis *x		  = newAxisSet.xAxis;
            CPTXYAxis *y = newAxisSet.yAxis;
            
            x.title = @"Fasting Hours";
            x.titleOffset = -30;
            x.majorIntervalLength		  = CPTDecimalFromFloat(5.0);
            x.orthogonalCoordinateDecimal = CPTDecimalFromFloat(0);
            x.minorTicksPerInterval		  = 0;

            
            NSArray *exclusionRanges = [NSArray arrayWithObjects:
                                        [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-30) length:CPTDecimalFromFloat(29)],
                                        nil];
            y.labelExclusionRanges = exclusionRanges;
            double newLocation = newRange.locationDouble;
            
            //NSLog(@"newLocation is %f",newLocation);
            double newLength = newRange.lengthDouble;
            newLocation = newLocation + newLength/2;
            y.orthogonalCoordinateDecimal = CPTDecimalFromDouble(newLocation);
            
            [self.graph.axisSet setAxes:[NSArray arrayWithObjects:x,y, nil]];
        } 
        return newRange;
    }
    
    
    if (self.xAxisSegmentedControl.selectedSegmentIndex == DATE) {
        CPTXYPlotSpace * plot_space = (CPTXYPlotSpace*)space;
        plot_space.globalYRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(-0.2*[self maxLevel]) length:CPTDecimalFromDouble([self maxLevel]+85.0)];
        
        if (coordinate == CPTCoordinateX) {
            CPTXYAxisSet *newAxisSet = [[CPTXYAxisSet alloc] initWithFrame:self.graph.axisSet.frame];
            newAxisSet = (CPTXYAxisSet *) self.graph.axisSet;
            CPTXYAxis *x		  = newAxisSet.xAxis;
            CPTXYAxis *y = newAxisSet.yAxis;
            
            x.majorIntervalLength		  = CPTDecimalFromFloat(newRange.lengthDouble/4);
            x.orthogonalCoordinateDecimal = CPTDecimalFromFloat(0);
            x.minorTicksPerInterval		  = 3;
            
            NSArray *exclusionRanges = [NSArray arrayWithObjects:
                                        [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-30) length:CPTDecimalFromFloat(29)],
                                        nil];
            y.labelExclusionRanges = exclusionRanges;
            double newLocation = newRange.locationDouble;
            
            //NSLog(@"newLocation is %f",newLocation);
            double newLength = newRange.lengthDouble;
            newLocation = newLocation + newLength/2;
            y.orthogonalCoordinateDecimal = CPTDecimalFromDouble(newLocation);
            
            [self.graph.axisSet setAxes:[NSArray arrayWithObjects:x,y, nil]];
        }
        return newRange;
    }
    
    if (self.xAxisSegmentedControl.selectedSegmentIndex == TIME_OF_DAY) {
        CPTXYAxisSet *newAxisSet;
        CPTXYPlotSpace * plot_space = (CPTXYPlotSpace*)space;
        
//        plot_space.globalYRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(-0.0) length:CPTDecimalFromDouble(0.0)];
        plot_space.globalYRange				= [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(-0.2*[self maxLevel]) length:CPTDecimalFromDouble([self maxLevel]+85.0)];

        if (coordinate == CPTCoordinateX) {
            newAxisSet = [[CPTXYAxisSet alloc] init];
            
            CPTXYAxis *x = newAxisSet.xAxis;
            CPTXYAxis *y = newAxisSet.yAxis;
            x.title = @"Time of Day";
            x.titleOffset = -30;
            
            x.majorIntervalLength		  = CPTDecimalFromFloat(4); // divide x axis by hours which is 60*60 seconds
            x.orthogonalCoordinateDecimal = CPTDecimalFromFloat(0);
            x.minorTicksPerInterval		  = 0;


            NSArray *exclusionRanges = [NSArray arrayWithObjects:
                                        [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-30) length:CPTDecimalFromFloat(29)],
                                        nil];
            y.labelExclusionRanges = exclusionRanges;
            double newLocation = newRange.locationDouble;
            
            //NSLog(@"newLocation is %f",newLocation);
            double newLength = newRange.lengthDouble;
            newLocation = newLocation + newLength/2;
            y.orthogonalCoordinateDecimal = CPTDecimalFromDouble(newLocation);
            
            //[self.graph.axisSet setAxes:[NSArray arrayWithObjects:x,y, nil]];
        } 
        return newRange;
    }
    NSLog(@"Uh Oh!");
    return newRange;
}

#pragma mark -
#pragma mark Utilities for data

 - (NSDate *) getEarliestDate {
     NSDate *d = [(Reading *)[[readings sortedArrayUsingSelector:@selector(compare:)] objectAtIndex:0] timeStamp];
     return d;
}

- (NSDate *) getLatestDate {
    NSDate *d = [(Reading *)[[readings sortedArrayUsingSelector:@selector(compare:)] lastObject] timeStamp];
    return d;
}

- (NSInteger) timeOfDay:(Reading *)r {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    NSString *t = [dateFormatter stringFromDate:r.timeStamp];
    NSArray *hms = [t componentsSeparatedByString:@":"];
    NSInteger tod = [[hms objectAtIndex:0] intValue] * 60 * 60;
    tod += [[hms objectAtIndex:1] intValue] * 60;
    tod += [[hms objectAtIndex:2] intValue];
    return tod/60/60;
}
     
- (Reading *) getEarliestTimeOfDayReading {
    Reading *r = (Reading *)[[self.readings sortedArrayUsingSelector:@selector(compareTimeOfDay:)] objectAtIndex:0];
    return r;
}

- (NSArray *) sortReadingsByTimeOfDay {
    return [self.readings sortedArrayUsingSelector:@selector(compareTimeOfDay:)];
}

- (float) maxLevel {
    NSNumber *max = 0;
    NSArray *displayedPoints = self.readings;
    
    for (Reading *r in displayedPoints) {
        if ([max floatValue] < [r.level floatValue]) {
            max = r.level;
        }
    }
    return [max floatValue];
}

- (float) minLevel {
    NSNumber *min= [NSNumber numberWithInt:1000];
    NSArray *displayedPoints = self.readings;
    for (Reading *r in displayedPoints) {
        if ([min floatValue] > [r.level floatValue]) {
            min = r.level;
        }
    }
    return [min floatValue];
}


- (IBAction)refreshGraph:(id)sender {
    [self updateGraph];
}
@end
