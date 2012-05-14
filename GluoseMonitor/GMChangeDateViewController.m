//
//  GMChangeDateViewController.m
//  GluoseMonitor
//
//  Created by Michael Toth on 4/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GMChangeDateViewController.h"

@interface GMChangeDateViewController ()

@end

@implementation GMChangeDateViewController
@synthesize datePicker;

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
    datePicker.datePickerMode = UIDatePickerModeDate;
	datePicker.hidden = NO;
	datePicker.date = [NSDate date];
	[datePicker addTarget:self
	               action:@selector(changeDateInLabel:)
	     forControlEvents:UIControlEventValueChanged];
}

- (void)changeDateInLabel:(id)sender {
    NSDate *date = datePicker.date;
    
}
- (void)viewDidUnload
{
    [self setDatePicker:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
