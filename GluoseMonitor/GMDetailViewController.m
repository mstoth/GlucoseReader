//
//  GMDetailViewController.m
//  GluoseMonitor
//
//  Created by Michael Toth on 4/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GMDetailViewController.h"
#import "CorePlot-CocoaTouch.h"
#import "DisplayView.h"
#import "gsllib.h"
#include <math.h> 

#include "gsl_vector.h"
#include "gsl_multifit.h"

@interface GMDetailViewController () {
    NSDate *referenceDate;
    BOOL vsTime;
    UITextView *notesView;
}
- (void)configureView;
@end

@implementation GMDetailViewController {
    NSMutableArray *displayedPoints;
}
@synthesize activityIndicator;
@synthesize range;
@synthesize hintsLabel;
@synthesize notesButton;
@synthesize Go,A,B,C;
@synthesize graph;
@synthesize dataForPlot;
@synthesize bestFitDataForPlot;
@synthesize dateButton;
@synthesize reading = _reading;
@synthesize fastingSlider = _fastingSlider;
@synthesize fastingTextField = _fastingTextField;
@synthesize levelSlider = _levelSlider;
@synthesize levelTextField = _levelTextField;
@synthesize graphView = _graphView;
@synthesize detailDescriptionLabel = _detailDescriptionLabel;
@synthesize delegate = _delegate;
@synthesize saveButton;
@synthesize readings = _readings;
@synthesize emailButton;
@synthesize viewButton;
@synthesize graphHost;
@synthesize datePicker;
@synthesize notesView;

#pragma mark - Managing the detail item

- (void)setReadings:(NSArray *)newReadings {
    if (_readings != newReadings) {
        _readings = newReadings;
        //[self configureView];
    }
}
- (void)setReading:(Reading *)newReading
{
    if (_reading != newReading) {
        _reading = newReading;
        referenceDate = _reading.timeStamp;
        // Update the view.
        [self configureView];
    }
    //NSLog(@"reading level is %d",[[newReading valueForKey:@"level"] intValue]);
}

- (void)createGraph2 {
    // creates a graph of glucose readings vs fasting hours
    
    self.graph = [[CPTXYGraph alloc] initWithFrame:CGRectZero];
	CPTTheme *theme = [CPTTheme themeNamed:kCPTDarkGradientTheme];
	[self.graph applyTheme:theme];
    
    _graphView.hostedGraph = self.graph;
    
	self.graph.paddingLeft	= 10.0;
	self.graph.paddingTop	= 10.0;
	self.graph.paddingRight	= 10.0;
	self.graph.paddingBottom = 10.0;
    
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
    if ([_readings count]>=10)
    self.graph.legend = [CPTLegend legendWithPlots:[NSArray arrayWithObjects:boundLinePlot, bestFitPlot, nil]];
    else {
        self.graph.legend = [CPTLegend legendWithPlots:[NSArray arrayWithObjects:boundLinePlot, nil]];
    }
	self.graph.legend.textStyle		 = x.titleTextStyle;
	self.graph.legend.fill			 = [CPTFill fillWithColor:[CPTColor darkGrayColor]];
	self.graph.legend.borderLineStyle = x.axisLineStyle;
	self.graph.legend.cornerRadius	 = 5.0;
	self.graph.legend.swatchSize		 = CGSizeMake(25.0, 25.0);
	self.graph.legendAnchor			 = CPTRectAnchorTopRight;
	self.graph.legendDisplacement	 = CGPointMake(0, 0.0);

    //NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Reading"];
    
    displayedPoints = [self.readings mutableCopy];
	NSMutableArray *contentArray = [[NSMutableArray alloc] init];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:NO];
    [displayedPoints sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    NSDate *latestDate = [(Reading *)[displayedPoints objectAtIndex:0] timeStamp];
	NSUInteger i;
	for ( i = 0; i < [displayedPoints count]; i++ ) {
        Reading *r = [displayedPoints objectAtIndex:i];
        if (self.range > 0) {
            //NSLog(@"Date by adding time interval is %@",[latestDate dateByAddingTimeInterval:(0.0 - self.range)]);
            if ([r.timeStamp timeIntervalSinceDate:[latestDate dateByAddingTimeInterval:(0.0 - self.range)]] >= 0) {
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
    [self.activityIndicator startAnimating];
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
        [[_graphView.hostedGraph plotSpaceAtIndex:0] 
         setPlotRange:[CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(-0.2*maxYval) 
                                                   length:CPTDecimalFromDouble(90+maxYval)] forCoordinate:CPTCoordinateY];
    }
    [_graphView.hostedGraph reloadData];
    [self.activityIndicator stopAnimating];
}

- (void)createGraph {
    Reading *lastReading,*firstReading;
    
    NSTimeInterval xRange;
    displayedPoints = [[NSMutableArray alloc] init];
    if ([_readings count]>0) {
        for (Reading *r  in _readings) {
            [displayedPoints addObject:r];
        }
        NSArray  *sortedPoints = [displayedPoints sortedArrayUsingSelector:@selector(compare:)];
        displayedPoints = [sortedPoints mutableCopy];
        lastReading = [displayedPoints objectAtIndex:[displayedPoints count]-1];
        firstReading = [displayedPoints objectAtIndex:0];
        //NSLog(@"%@",firstReading.description);
        xRange = [lastReading.timeStamp timeIntervalSinceDate:firstReading.timeStamp];
        referenceDate = _reading.timeStamp;
        xRange = [lastReading.timeStamp timeIntervalSinceDate:firstReading.timeStamp];
        xRange = xRange;
    } else {
        return;
    }

    // Create graph from theme
	self.graph = [[CPTXYGraph alloc] initWithFrame:CGRectZero];
	CPTTheme *theme = [CPTTheme themeNamed:kCPTDarkGradientTheme];
	[self.graph applyTheme:theme];
    _graphView.hostedGraph = self.graph;
    
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
	myDateFormatter.referenceDate = _reading.timeStamp;
	x.labelFormatter			  = myDateFormatter;
    
    NSDateFormatter *df = [NSDateFormatter new];
    [df setDateFormat:@"mm/dd/yyyy - hh:mma"];
    self.title = [df stringFromDate:[_reading valueForKey:@"timeStamp"]];
    
	CPTXYAxis *y = axisSet.yAxis;
	y.majorIntervalLength		  = CPTDecimalFromString(@"25");
	y.minorTicksPerInterval		  = 1;
	y.orthogonalCoordinateDecimal = CPTDecimalFromFloat(0);
	NSArray *exclusionRanges = [NSArray arrayWithObjects:[CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-100) length:CPTDecimalFromFloat(101)],nil];
	y.labelExclusionRanges = exclusionRanges;
	y.delegate			   = self;
    
	// Create a blue plot area
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
	for ( i = 0; i < [_readings count]; i++ ) {
        Reading *r = [_readings objectAtIndex:i];
        NSTimeInterval seconds = [r.timeStamp timeIntervalSinceDate:referenceDate];
        NSNumber *n = [NSNumber numberWithDouble:seconds];
        float scaledHours = [r.fastingHours floatValue]*10;
        NSNumber *hours = [NSNumber numberWithFloat:scaledHours];
		id x = n;
		id y = r.level;
        id h = hours;
		[contentArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:x, @"x", y, @"y", h, @"h", nil]];
	}
	self.dataForPlot = contentArray;
    [_graphView.hostedGraph reloadData];
    [self.activityIndicator stopAnimating];
}

#pragma mark - CPTLegendDelegate methods

- (BOOL) legend:(CPTLegend *)legend shouldDrawSwatchAtIndex:(NSUInteger)index forPlot:(CPTPlot *)plot inRect:(CGRect)rect inContext:(CGContextRef)context {
    return YES;
}



- (void) init:(id)sender {
    [self configureView];
}

- (void)configureView {
    vsTime = true;
    [self createGraph];
    NSDateFormatter *df = [NSDateFormatter new];
    [df setDateFormat:@"MMMM dd - hh:mma"];
    self.title = [df stringFromDate:[_reading valueForKey:@"timeStamp"]];
    [_fastingTextField addTarget:self action:@selector(fastingFieldFinished:) forControlEvents:UIControlEventEditingDidEndOnExit];
    [_levelTextField addTarget:self action:@selector(levelFieldFinished:) forControlEvents:UIControlEventEditingDidEndOnExit];

    int levelValue = 0;
    levelValue = [_reading.level intValue];
    [_levelSlider setMinimumValue:[_reading.level floatValue] - 70];
    [_levelSlider setMaximumValue:[_reading.level floatValue] + 70];
    if ([_reading.level floatValue] < 130) {
        [_levelSlider setMinimumValue:60];
        [_levelSlider setMaximumValue:200];
    }
    _levelTextField.text = [NSString stringWithFormat:@"%.0f",[_reading.level floatValue]];
    

    float fastLevel = [_reading.fastingHours floatValue];
    _fastingTextField.text = [NSString stringWithFormat:@"%.0f",fastLevel];

    [_levelSlider setValue:levelValue];
    [_fastingSlider setValue:[[_reading valueForKey:@"fastingHours"] floatValue]];
    [_levelSlider addTarget:self action:@selector(levelDidChange:) forControlEvents:UIControlEventValueChanged];
    [_fastingSlider setMinimumValue:0];
    [_fastingSlider setMaximumValue:12];
    [_fastingSlider addTarget:self action:@selector(fastingDidChange:) forControlEvents:UIControlEventValueChanged];
    
}

- (NSNumber *)previousValue {
    NSUInteger index = [_readings indexOfObject:_reading];
    if (index < ([_readings count]-1)) {
        Reading *r = [_readings objectAtIndex:(index+1)];
        return r.level;
    } else {
        return nil;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}

- (void)viewDidUnload
{
    [self setGraphView:nil];
    [self setLevelTextField:nil];
    [self setLevelSlider:nil];
    [self setFastingTextField:nil];
    [self setFastingSlider:nil];
    [self setDateButton:nil];
    [self setSaveButton:nil];
    [self setEmailButton:nil];
    [self setViewButton:nil];
    [self setActivityIndicator:nil];
    [self setNotesButton:nil];
    [self setHintsLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    self.detailDescriptionLabel = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown ||
            interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)fastingDidChange:(id)sender {
    //NSNumber *number = [NSNumber numberWithFloat:[_fastingSlider value]];
    float number = [_fastingSlider value];
    _fastingTextField.text  = [NSString stringWithFormat:@"%.0f",number];
    
}
- (void)levelDidChange:(id)sender {
    float number = [_levelSlider value];
    _levelTextField.text = [NSString stringWithFormat:@"%.0f",number] ;
}

- (IBAction)save:(id)sender {
    BOOL found = false;
    for (UIView *subview in [self.view subviews]) {
        if (subview.tag == 100){
            [subview removeFromSuperview];
            found = true;
        }
    }
    if (!found) {
        _reading.level = [NSNumber numberWithFloat:[_levelTextField.text floatValue]];
        _reading.fastingHours = [NSNumber numberWithFloat:[_fastingTextField.text floatValue]];
        [_delegate addReading:[NSNumber numberWithFloat:[_levelTextField.text floatValue]]
                      fasting:[NSNumber numberWithFloat:[_fastingTextField.text floatValue]]];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (float) minLevel {
    NSNumber *min= [NSNumber numberWithInt:1000];
    for (Reading *r in displayedPoints) {
        if ([min floatValue] > [r.level floatValue]) {
            min = r.level;
        }
    }
    return [min floatValue];
}
- (float) maxLevel {
    NSNumber *max = 0;
    for (Reading *r in displayedPoints) {
        if ([max floatValue] < [r.level floatValue]) {
            max = r.level;
        }
    }
    return [max floatValue];
}

- (NSString *)reportBody {
    NSString *report = [[NSString alloc] init];
    
    report = [report stringByAppendingFormat:@"<ul>"];
    float max = [self maxLevel];
    float min = [self minLevel];
    for (Reading *r in displayedPoints) {
        NSDateFormatter *df = [NSDateFormatter new];
        [df setDateFormat:@"M/dd - hh:mma"];

        report = [report stringByAppendingFormat:@"<li>%@</li><ul><li>%.2f (mg/dL)</li><li>%.2f (hours)</li>",[df stringFromDate:[r valueForKey:@"timeStamp"]],[r.level floatValue],[[r fastingHours] floatValue]];
        if (r.notes) {
            report = [report stringByAppendingFormat:@"<li>Notes: %@</li></ul>",r.notes];
        } else {
            report = [report stringByAppendingFormat:@"</ul>"];
        }
        
    }
    NSString *headerString = @"<html><body><h3>Glucose Readings</h3><hr/>";
    headerString = [headerString stringByAppendingFormat:@"<br/>Maximum Glucose Level is %.2f\nMinimum Glucose Level is %.2f\n",max ,min];
    report = [headerString stringByAppendingFormat:@"%@",report];
    report = [report stringByAppendingFormat:@"</body></html>"];
    return report;
}

-(IBAction) sendReportToDoctor:(id)sender {
    //[self sendEmailTo:@"" withSubject:@"Glucose Reading" withBody:[self reportBody]];
    [self actionEmailComposer];
}

- (IBAction)actionEmailComposer {
    NSMutableString *csvFileContents;
    NSString *line;
    NSDateFormatter *df = [NSDateFormatter new];
    [df setDateFormat:@"M/dd - hh:mma"];
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
        mailViewController.mailComposeDelegate = self;
        [mailViewController setSubject:@"Glucose Readings"];
        //[mailViewController setToRecipients:[NSArray arrayWithObject:@""]];
        [mailViewController setMessageBody:[self reportBody] isHTML:YES];
        NSString *path = NSHomeDirectory();
        path = [path stringByAppendingPathComponent:@"Documents/glucose.csv"];
        NSFileManager *fm = [NSFileManager defaultManager];
        csvFileContents = [[NSMutableString alloc] init];
        line = [[NSMutableString alloc] init];
        line = [line stringByAppendingFormat:@"Date,Glucose Level (mg/dL),Fasting Hours,Notes\n"];
        for (Reading *r in displayedPoints) {
            if (r.notes == nil) {
                r.notes = @"";
            }
            line = [line stringByAppendingFormat:@"%@,%.2f,%.2f,%@\n",[df stringFromDate:[r valueForKey:@"timeStamp"]],[r.level floatValue],[[r fastingHours] floatValue],[r notes]];

        }
        [fm createFileAtPath:path contents:[line dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
        [mailViewController addAttachmentData:[line dataUsingEncoding:NSUTF8StringEncoding] mimeType:@"text/csv" fileName:[path lastPathComponent]];
        [self presentModalViewController:mailViewController animated:YES];       
    }
}


-(void) sendEmailTo:(NSString *)to withSubject:(NSString *)subject withBody:(NSString *)body {
    NSString *mailString = [NSString stringWithFormat:@"mailto:?to=%@&subject=%@&body=%@",
                            [to stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
                            [subject stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
                            [body stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:mailString]];
}

-(void)mailComposeController:(MFMailComposeViewController*)controller 
         didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    NSString *path = NSHomeDirectory();
    path = [path stringByAppendingPathComponent:@"Documents/glucose.csv"];
    [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    [controller dismissModalViewControllerAnimated:YES];
}


- (IBAction)cancel:(id)sender {
    [self.view endEditing:YES];
}

- (IBAction)changeDate:(id)sender {
    [self.view endEditing:YES];
    if ([self.dateButton.titleLabel.text isEqualToString:@"Done"]) {
        [self.dateButton setTitle:@"Date" forState:UIControlStateNormal];
        [self showButtons:nil];
        self.levelTextField.enabled = YES;
        self.fastingTextField.enabled = YES;
        BOOL found = false;
        for (UIView *subview in [self.view subviews]) {
            if (subview.tag == 100){
                [subview removeFromSuperview];
                found = true;
            }
        }
        [self.view endEditing:NO];
        [self.emailButton setEnabled:true];
        [self.emailButton setHidden:false];
        [self.saveButton setEnabled:true];
        [self.saveButton setHidden:false];
    } else {
        [self hideButtons:nil];
        self.dateButton.hidden = NO;
        self.levelTextField.enabled = NO;
        self.fastingTextField.enabled = NO;
        [self.dateButton setTitle:@"Done" forState:UIControlStateNormal];
        datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 200, 325, 250)];
        datePicker.datePickerMode = UIDatePickerModeDateAndTime;
        datePicker.date = _reading.timeStamp;
        datePicker.tag = 100;
        datePicker.hidden = NO;
        [datePicker addTarget:self
                       action:@selector(changeDateInReading:)
             forControlEvents:UIControlEventValueChanged];
        [self.view addSubview:datePicker];
        [self.saveButton setHidden:true];
        [self.saveButton setEnabled:false];
        [self.emailButton setHidden:true];
        [self.emailButton setEnabled:false];
    }
}

- (void)changeDateInReading:(id)sender {
    _reading.timeStamp = datePicker.date;
    NSDateFormatter *df = [NSDateFormatter new];
    [df setDateFormat:@"MM/dd - hh:mma"];
    self.title = [df stringFromDate:[_reading valueForKey:@"timeStamp"]];
}
- (IBAction)sendData:(id)sender {
}

- (IBAction)hideButtons:(id)sender {
    self.notesButton.hidden = YES;
    self.emailButton.hidden = YES;
    self.viewButton.hidden = YES;
    self.dateButton.hidden = YES;
}

- (IBAction)showButtons:(id)sender {
    self.notesButton.hidden = NO;
    self.emailButton.hidden = NO;
    self.viewButton.hidden = NO;
    self.dateButton.hidden = NO;
}

- (void)levelFieldFinished:(id)sender {
    [sender resignFirstResponder];
}
- (void)fastingFieldFinished:(id)sender {
    
    [sender resignFirstResponder];
}
- (void)textViewDidEndEditing:(UITextView *)textView {
    [textView resignFirstResponder];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@","]) {
        return NO;
    }
    return YES;
}


- (IBAction)editNotes:(id)sender {
    notesView = [[UITextView alloc] initWithFrame:CGRectMake(4, 4, 312, 184)];
    [notesView setDelegate:self];
    notesView.text = _reading.notes;
    [notesView setFont:[UIFont systemFontOfSize:18]];
    [self.view addSubview:notesView];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleDone target:self action:@selector(doneEditingNotes:)];
    [self.navigationItem setRightBarButtonItem:doneButton];
    [notesView becomeFirstResponder];
    //self.navigationController.navigationItem.rightBarButtonItem = doneButton;
    
}


- (IBAction)changePlot:(id)sender {
    [self.activityIndicator startAnimating];
    if (vsTime) {
        if (self.range == 0) {
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:NO];
            NSMutableArray *readingsArray = [[NSMutableArray alloc] init];
            readingsArray = [_readings mutableCopy];
            [readingsArray sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
            
            self.range = [[[readingsArray objectAtIndex:0] timeStamp] timeIntervalSinceDate:[[readingsArray lastObject] timeStamp]];

            [viewButton setTitle:@"All" forState:UIControlStateNormal];
        } else if ([viewButton.titleLabel.text isEqualToString:@"All"]) {
            self.range = 60*60*24*30;
            [viewButton setTitle:@"1 Month" forState:UIControlStateNormal];
        } else if ([viewButton.titleLabel.text isEqualToString:@"1 Month"]) {
            self.range = 60*60*24*60;
            [viewButton setTitle:@"2 Months" forState:UIControlStateNormal];
        } else {
            self.range = 60*60*24*90;
            [viewButton setTitle:@"3 Months" forState:UIControlStateNormal];
            vsTime = false;
        }
        [self createGraph2];
    } else {
        vsTime = true;
        self.range = 0;
        [viewButton setTitle:@"View" forState:UIControlStateNormal];
        [self createGraph];
    }
}

- (void)doneEditingNotes:(id)sender {
    [self.view endEditing:NO];
    _reading.notes = notesView.text;
    [notesView removeFromSuperview];
    [self.navigationItem setRightBarButtonItem:nil];
}


- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == _levelTextField) {
        [_levelSlider setValue:[_levelTextField.text floatValue]];
    }
    if (textField == _fastingTextField) {
        [_fastingSlider setValue:[_fastingTextField.text floatValue]];
    }
}


#pragma mark -
#pragma mark Plot Space Delegate Methods

-(CPTPlotRange *)plotSpace:(CPTPlotSpace *)space willChangePlotRangeTo:(CPTPlotRange *)newRange forCoordinate:(CPTCoordinate)coordinate
{
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
        
        NSLog(@"newLocation is %f",newLocation);
        double newLength = newRange.lengthDouble;
        newLocation = newLocation + newLength/2;
        y.orthogonalCoordinateDecimal = CPTDecimalFromDouble(newLocation);
        
        [self.graph.axisSet setAxes:[NSArray arrayWithObjects:x,y, nil]];
    } 
    return newRange;
}



#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    if ([(NSString *)plot.identifier isEqualToString:@"bestFit"]) {
        if ([_readings count]<10) {
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
            return [[bestFitDataForPlot objectAtIndex:index] valueForKey:key];
    }
    if ( [(NSString *)plot.identifier isEqualToString:@"Green Plot"] ) {
        if ([key isEqualToString:@"y"]) 
            key=@"h";
    }
    NSNumber *num = [[dataForPlot objectAtIndex:index] valueForKey:key];
    //NSLog(@"Returning %f",[num floatValue]);
    return num;
}


@end
