//
//  GMMasterViewController.h
//  GluoseMonitor
//
//  Created by Michael Toth on 4/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "GMDetailViewController.h"
#import "Reading.h"

@interface GMMasterViewController: UITableViewController 
    <NSFetchedResultsControllerDelegate,GMDetailViewDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) Reading *selectedReading;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (weak, nonatomic) NSArray *readings;

@end
