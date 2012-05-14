//
//  GMMasterViewController.m
//  GluoseMonitor
//
//  Created by Michael Toth on 4/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GMMasterViewController.h"

#import "GMDetailViewController.h"

@interface GMMasterViewController () 
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
@end

@implementation GMMasterViewController
@synthesize selectedReading = _selectedReading;
@synthesize fetchedResultsController = __fetchedResultsController;
@synthesize persistentStoreCoordinator = __persisstentStoreCoordinator;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize readings = _readings;

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.tableView reloadData];
    self.title = @"Glucose Readings";
    
}
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;
    //NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    _readings = [self.fetchedResultsController fetchedObjects];
    
    self.navigationController.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"flare.png"]]; self.tableView.backgroundColor = [UIColor clearColor];

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown ||
            interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)insertNewObject:(id)sender
{
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
    //NSLog(@"Entity name is %@",[entity name]);
    _selectedReading = [NSEntityDescription insertNewObjectForEntityForName:[entity name] 
                                                        inManagedObjectContext:context];
    
    _selectedReading.timeStamp = [NSDate date];
    _selectedReading.level = [NSNumber numberWithInt:-1];
    _selectedReading.fastingHours = [NSNumber numberWithInt:0];
    
    NSDateFormatter *df = [NSDateFormatter new];
    [df setDateFormat:@"MMMM dd, yyyy - hh:mma"];
    //NSLog(@"Selected reading time stamp is %@",[df stringFromDate:_selectedReading.timeStamp]);
    //_selectedReading.notes = @"Notes for %@",[df stringFromDate:_selectedReading.timeStamp];
    
    /*NSMutableArray *rds = [[NSMutableArray alloc] init];
    rds = [_readings mutableCopy];
    [rds addObject:_selectedReading];
    _readings = rds;
     */
    // Save the context.
    NSError *error = nil;
    if (![context save:&error]) {
         // Replace this implementation with code to handle the error appropriately.
         // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
        //NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    _readings = [self.fetchedResultsController fetchedObjects];
    
    //NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    //NSArray *readings = [[self fetchedResultsController] fetchedObjects];
    //Reading *reading = [[self fetchedResultsController] objectAtIndexPath:indexPath];
    //_selectedReading = [self.fetchedResultsController objectAtIndexPath:[self.tableView indexPathForSelectedRow]];
    [self.fetchedResultsController performFetch:&error];
    [self performSegueWithIdentifier:@"showDetail" sender:self];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
        
        NSError *error = nil;
        if (![context save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            //NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }   
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // The table view should not be re-orderable.
    return NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSArray *readings = [self getReadings];
        if ([[_selectedReading valueForKey:@"level"]intValue] == -1) { // it's a new reading
            if ([readings count]==0) {
                [_selectedReading setLevel:[NSNumber numberWithInt:80]];
            } else {
                if ([_readings indexOfObject:_selectedReading]<[readings count]-1) {
                    int index = [readings indexOfObject:_selectedReading];
                    Reading *r = [readings objectAtIndex:index+1];
                    [_selectedReading setLevel:r.level];
                } else {
                    [_selectedReading setLevel:[NSNumber numberWithInt:80]];
                }
            }
        } else {
            _selectedReading = [self.fetchedResultsController objectAtIndexPath:[self.tableView indexPathForSelectedRow]];
        }
        
        //NSLog(@"reading level is %f",[[_selectedReading valueForKey:@"level"] floatValue]);
        [[segue destinationViewController] setDelegate:self];
        [[segue destinationViewController] setReading:_selectedReading];
        //NSLog(@"readings has %d objects.",[[self getReadings] count]);
        [[segue destinationViewController] setReadings:[self getReadings]];
        //[[[[segue destinationViewController] navigationBar] backItem] setTitle:@"Back"];
        //self.navigationController.navigationBar.backItem.title = @"Back";
        self.title = @"Back";
    }
}

#pragma mark - DetailViewDelegate Methods

-(void)addReading:(NSNumber *)level fasting:(NSNumber *)fasting {
    NSError *error = nil;
    
    [self.fetchedResultsController performFetch:&error];
    _selectedReading = [self.fetchedResultsController objectAtIndexPath:[self.tableView indexPathForSelectedRow]];
    _selectedReading.level = level;
    _selectedReading.fastingHours = fasting;

    if (![self.fetchedResultsController.managedObjectContext save:&error]) {
        //NSLog(@"Error saving in addReading");
    }
    //NSLog(@"Saving %f and %f (%f and %f)",[level floatValue],[fasting floatValue],[_selectedReading.level floatValue],[_selectedReading.fastingHours floatValue]);
}


-(NSArray *)getReadings {
    NSArray *readings = [[NSArray alloc] initWithArray:[[self fetchedResultsController] fetchedObjects]];
    //NSLog(@"Readings has %d objects.",[readings count]);
    return readings;
}




#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (__fetchedResultsController != nil) {
        return __fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Reading" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	     // Replace this implementation with code to handle the error appropriately.
	     // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
	    //NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return __fetchedResultsController;
}    

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

/*
// Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed. 
 
 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    // In the simplest, most efficient, case, reload the table view.
    [self.tableView reloadData];
}
 */

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSError *error = nil;
    [self.fetchedResultsController performFetch:&error];
    NSArray *currentReadings = [self.fetchedResultsController fetchedObjects];
    //NSLog(@"currentReadings has %d objects.",[currentReadings count]);
    Reading *selectedReading = [currentReadings objectAtIndex:[indexPath row]];
    
    NSDateFormatter *df = [NSDateFormatter new];
    [df setDateFormat:@"MMMM dd, yyyy - hh:mma"];
    
    for (UIView *subview in [cell.contentView subviews]) {
        if (subview.tag == 101) {
            [subview removeFromSuperview];
        }
    }
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.text = [df stringFromDate:[selectedReading valueForKey:@"timeStamp"]];   
    CGRect f = cell.detailTextLabel.frame;
    CGRect nf = CGRectMake(320-f.origin.x, f.origin.y, f.size.width, f.size.height);
    cell.detailTextLabel.frame = nf;
    cell.detailTextLabel.bounds = nf;
    if ([selectedReading.level floatValue] == 0) {
        [selectedReading  setLevel:[NSNumber numberWithInt:80]];
    }
    UILabel *chartLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, [selectedReading.level floatValue], 15.0)];
    chartLabel.tag = 101;
    
    chartLabel.font = [UIFont systemFontOfSize:14.0];
    chartLabel.backgroundColor = [UIColor colorWithRed:([selectedReading.level floatValue]+30)/255.0 green:(300-[selectedReading.level floatValue])/255.0 blue:41.0/255.0 alpha:1.0];

    chartLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
    
    [cell.contentView addSubview:chartLabel];    //cell.textLabel.backgroundColor = [UIColor greenColor];
    //cell.textLabel.text = [[reading valueForKey:@"timeStamp"] description];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d",
                                 [[selectedReading valueForKey:@"level"] intValue]];
}

@end
