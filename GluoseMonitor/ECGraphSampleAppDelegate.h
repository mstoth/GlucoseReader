//
//  ECGraphicTestAppDelegate.h
//  ECGraphicTest
//
//  Created by ris on 10-4-17.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ECGraphViewController;

@interface ECGraphSampleAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    ECGraphViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet ECGraphViewController *viewController;

@end

