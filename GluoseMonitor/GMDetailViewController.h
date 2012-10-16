//
//  GMDetailViewController.h
//  GluoseMonitor
//
//  Created by Michael Toth on 4/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DisplayView.h"
#import "CorePlot-CocoaTouch.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

//#import "GMMasterViewController.h"
#import "Reading.h"

@protocol GMDetailViewDelegate;

@interface GMDetailViewController : UIViewController <CPTLegendDelegate, UITextViewDelegate, CPTPlotDataSource,UITextFieldDelegate,UIPickerViewDelegate, CPTPlotSpaceDelegate, MFMailComposeViewControllerDelegate> {
	IBOutlet CPTGraphHostingView *hostView;
	NSArray *plotData;
	CPTFill *areaFill;
	CPTLineStyle *barLineStyle;
	CPTGraphHostingView *graphHost;
	NSMutableArray *dataForPlot;

}
@property (nonatomic) NSTimeInterval range; 

@property (weak, nonatomic) IBOutlet UILabel *hintsLabel;
@property (weak, nonatomic) IBOutlet UIButton *notesButton;
@property (nonatomic, retain) CPTXYGraph *graph;
@property (nonatomic, retain) IBOutlet CPTGraphHostingView *graphHost;
@property (nonatomic, retain) NSMutableArray *dataForPlot;
@property (nonatomic, retain) NSMutableArray *bestFitDataForPlot;
@property (weak, nonatomic) IBOutlet UIButton *dateButton;
@property (strong, nonatomic) Reading *reading;
- (IBAction)save:(id)sender;
- (void) fastingDidChange:(id)sender;
- (void) levelDidChange:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)changeDate:(id)sender;
- (IBAction)sendData:(id)sender;
- (IBAction)editNotes:(id)sender;
- (IBAction)showButtons:(id)sender;
- (IBAction)changePlot:(id)sender;
- (IBAction)hideButtons:(id)sender;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) NSNumber *Go,*A,*B,*C;
@property (strong, nonatomic) NSArray *readings;
@property (weak, nonatomic) IBOutlet UIButton *emailButton;
@property (weak, nonatomic) IBOutlet UIButton *viewButton;
@property (weak, nonatomic) IBOutlet UISlider *fastingSlider;
@property (weak, nonatomic) IBOutlet UITextField *fastingTextField;
@property (weak, nonatomic) IBOutlet UISlider *levelSlider;
@property (weak, nonatomic) IBOutlet UITextField *levelTextField;
@property (strong, nonatomic) IBOutlet CPTGraphHostingView *graphView;
@property (strong, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@property (weak, nonatomic) id<GMDetailViewDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (strong, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (nonatomic, retain) IBOutlet UITextView *notesView;
- (IBAction) sendReportToDoctor:(id)sender;
@end

@protocol GMDetailViewDelegate <NSObject>

@optional
-(void)addReading:(NSNumber *)level fasting:(NSNumber *)fasting;
-(NSArray *)getReadings;
@end