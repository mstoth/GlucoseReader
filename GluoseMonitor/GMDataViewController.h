//
//  GMDataViewController.h
//  GlucoseMonitor
//
//  Created by Michael Toth on 10/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

enum {
    TIME_OF_DAY, FASTING, DATE
};


#import <UIKit/UIKit.h>
#import "CorePlot-CocoaTouch.h"
#import "Reading.h"
@interface GMDataViewController : UIViewController <CPTLegendDelegate, CPTPlotDataSource, CPTPlotSpaceDelegate>

- (IBAction)refreshGraph:(id)sender;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) NSDate *earliestDateToPlot, *latestDateToPlot;
@property (nonatomic, strong) NSMutableArray *dataForPlot;
@property (nonatomic, strong) NSMutableArray *bestFitDataForPlot;
@property (nonatomic, strong) NSNumber *Go,*A,*B,*C;
@property (nonatomic) NSTimeInterval plotXRange; 
@property (weak, nonatomic) NSArray *readings;
@property (weak, nonatomic) IBOutlet CPTGraphHostingView *graphDataView;
@property (weak, nonatomic) IBOutlet UILabel *lowerLabel;
@property (weak, nonatomic) IBOutlet UILabel *upperLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *xAxisSegmentedControl;
@property (nonatomic, retain) CPTXYGraph *graph;
@property (strong, nonatomic) Reading *reading;

- (IBAction)xAxisTypeChanged:(id)sender;
- (IBAction)lowerStepper:(id)sender;
- (IBAction)upperStepper:(id)sender;
- (IBAction)lowerSlider:(id)sender;
- (IBAction)upperSlider:(id)sender;

@end
