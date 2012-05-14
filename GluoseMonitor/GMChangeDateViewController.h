//
//  GMChangeDateViewController.h
//  GluoseMonitor
//
//  Created by Michael Toth on 4/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GMChangeDateViewController : UIViewController <UIPickerViewDelegate>
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;

@end
