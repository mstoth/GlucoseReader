//
//  ECGraphicTestAppDelegate.m
//  ECGraphicTest
//
//  Created by ris on 10-4-17.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "ECGraphSampleAppDelegate.h"
#import "ECGraphViewController.h"

@implementation ECGraphSampleAppDelegate

@synthesize window;
@synthesize viewController;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    // Override point for customization after app launch    
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];
	
	return YES;
}


- (void)dealloc {
    [viewController release];
    [window release];
    [super dealloc];
}


@end
