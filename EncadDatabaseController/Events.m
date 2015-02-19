//
//  Events.m
//  EncadDatabaseController
//
//  Created by Bernd Fecht (encad-consulting.de) on 15.01.15.
//  Copyright (c) 2015 Bernd Fecht (encad-consulting.de). All rights reserved.
//

#import "Events.h"
#import <CoreData/CoreData.h>
#import "AppDelegate.h"
#import "Veranstaltung.h"
#import "EventCell.h"
#import "EventCreator.h"

@interface Events ()<NSFetchedResultsControllerDelegate>{
    AppDelegate *_delegate;
    NSFetchedResultsController *_fetchedResultController;
}

@property (nonatomic, strong) NSSortDescriptor *theDescriptor;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) NSString *entityName;

@end

@implementation Events

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //init core data fetch
    _entityName=@"Veranstaltung";
    _delegate = (AppDelegate*) [[UIApplication sharedApplication]delegate];
    self.theDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"anfangs_datum" ascending:YES];
    
    [self initCoreDataFetch];
    
    // Initialize the refresh control.
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor purpleColor];
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self
                            action:@selector(reloadData)
                  forControlEvents:UIControlEventValueChanged];

    //Initialize the spinner
    _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge]; [self.view addSubview:_spinner];
    [_spinner setColor:[UIColor purpleColor]];
    _spinner.center=CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
    
    self.navigationItem.title=self.entityName;
}

-(void)initCoreDataFetch{
    NSFetchRequest *request = self.fetchRequest;
    NSFetchedResultsController *theController = [[NSFetchedResultsController alloc]initWithFetchRequest:request managedObjectContext:_delegate.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    NSError *theError = nil;
    
    theController.delegate = self;
    if([theController performFetch:&theError]){
        _fetchedResultController = theController;
    }
    else{
        NSLog(@"Couldn't fetch the Result: %@", theError );
    }
}

/**
 Fetch request sort by date without predicate
 */
-(NSFetchRequest *)fetchRequest{
    NSFetchRequest *theFetch = [[NSFetchRequest alloc]init];
    NSEntityDescription *theType = [NSEntityDescription entityForName:self.entityName inManagedObjectContext:_delegate.managedObjectContext];
    theFetch.entity = theType;
    theFetch.sortDescriptors = @[self.theDescriptor];
    return theFetch;
}

-(BOOL)dateIsOld:(NSString*)dateString{
    NSDateFormatter *theFormatter = [[NSDateFormatter alloc]init];
    [theFormatter setDateFormat:@"yyyy-MM-dd"];
    NSDate *startDate = [theFormatter dateFromString:dateString];
    NSDate *currentDate = [NSDate date];
    if([startDate laterDate:currentDate]==currentDate){
        return YES;
    }
    return NO;
}

-(NSString*)convertDateString:(NSString*)dateString WithDaysToAdd:(long)days{
    days-=1;
    NSDateFormatter *theFormatter = [[NSDateFormatter alloc]init];
    [theFormatter setDateFormat:@"yyyy-MM-dd"];
    NSDate *startDate = [theFormatter dateFromString:dateString];
    NSDate *endDate = startDate;
    if(days>0){
        endDate = [startDate dateByAddingTimeInterval:60*60*24*days];
    }
    [theFormatter setDateFormat:@"EE, dd.MM.yyyy"];
    NSString *convertedDateString = [NSString stringWithFormat:@"von: %@ bis: %@",[theFormatter stringFromDate:startDate],[theFormatter stringFromDate:endDate]];
    return convertedDateString;
}

-(NSString*)convertDateString:(NSString*)dateString{
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSDate *convertedDate= [formatter dateFromString:dateString];
    [formatter setDateFormat:@"dd.MM.yyyy"];
    return [formatter stringFromDate:convertedDate];
}

-(void)deleteEventWithName:(NSString*)eventName{
    NSString *urlString =[[NSString alloc]initWithFormat:@"%@deleteEventData.php?name=%@&type=%@",[[NSUserDefaults standardUserDefaults] stringForKey:@"serverPath"],eventName,self.entityName];
    NSURL *url = [[NSURL alloc]initWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    NSURLRequest *request = [[NSURLRequest alloc]initWithURL:url];
    NSURLConnection *theConnection = [[NSURLConnection alloc]initWithRequest:request delegate:self];
    UIAlertAction *dismiss = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
    NSLog(@"connection: %@",theConnection);
    if(!theConnection){
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Löschen fehlgeschlagen" message:@"Der Daten-Upload ist fehlgeschlagen! Bitte informieren Sie den Administrator dieser App!" preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:dismiss];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Löschen erfolgreich" message:@"Löschen war erfolgreich!" preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:dismiss];
        [self presentViewController:alert animated:YES completion:nil];
    }
    [self reloadData];
    [self.spinner stopAnimating];
    [self.spinner setHidden:YES];
}

-(void)reloadData{
    [_delegate runWebinarScripts];
    [_delegate runVeranstaltungScripts];
    [self initCoreDataFetch];
    [self.tableView reloadData];
    // End the refreshing
    if (self.refreshControl) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"MMM d, h:mm a"];
        NSString *title = [NSString stringWithFormat:@"Letztes Update: %@", [formatter stringFromDate:[NSDate date]]];
        NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor whiteColor]
                                                                    forKey:NSForegroundColorAttributeName];
        NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:attrsDictionary];
        self.refreshControl.attributedTitle = attributedTitle;
        
        [self.refreshControl endRefreshing];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _fetchedResultController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id sectionInfo = [[_fetchedResultController sections]objectAtIndex:section];
    
    return  [sectionInfo numberOfObjects];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EventCell *cell = [tableView dequeueReusableCellWithIdentifier:@"eventCell" forIndexPath:indexPath];
    Veranstaltung *event = [_fetchedResultController objectAtIndexPath:indexPath];
    cell.nameLabel.text=event.name;
    cell.startDateLabel.text=event.anfangs_datum;
    cell.endDateLabel.text=event.end_datum;
    if([self.entityName isEqualToString:@"Veranstaltung"]){
        cell.locationLabel.text=event.ort;
    }
    else{
        cell.locationLabel.text=@"Webinar";
    }
    
    return cell;
}



// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.spinner startAnimating];
    [self.spinner setHidden:NO];
    Veranstaltung *event = [_fetchedResultController objectAtIndexPath:indexPath];
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *convertedStartDateString =[self convertDateString:event.anfangs_datum];
        NSString *convertedEndDateString = [self convertDateString:event.end_datum];
        NSString *message;
        NSString *title;
        if([self dateIsOld:event.anfangs_datum]){
            if([self.entityName isEqualToString:@"Veranstaltung"]){
            message = [NSString stringWithFormat:@"\nSind Sie sicher, dass Sie das Event '%@' vom '%@' bis '%@' in '%@' löschen wollen?",event.name,convertedStartDateString,convertedEndDateString,event.ort];
            }
            else{
                message = [NSString stringWithFormat:@"\nSind Sie sicher, dass Sie das Event '%@' vom '%@' bis '%@' löschen wollen?",event.name,convertedStartDateString,convertedEndDateString];
            }
            title=@"Löschen (alter Datensatz)";
        }
        else{
             if([self.entityName isEqualToString:@"Veranstaltung"]){
                 message = [NSString stringWithFormat:@"\nSind Sie sicher, dass Sie das Event '%@' vom '%@' bis '%@' in '%@' löschen wollen? Bei Fehlverhalten könnten schwerwiegende Konsequenzen entstehen!",event.name,convertedStartDateString,convertedEndDateString,event.ort];
             }
             else{
                 message = [NSString stringWithFormat:@"\nSind Sie sicher, dass Sie das Event '%@' vom '%@' bis '%@' löschen wollen? Bei Fehlverhalten könnten schwerwiegende Konsequenzen entstehen!",event.name,convertedStartDateString,convertedEndDateString];
             }
            title=@"Löschen (aktueller Datensatz)";
        }
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Nein, Abbrechen" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [self.spinner stopAnimating];
            [self.spinner setHidden:YES];
        }];
        
        UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"Ja, Datensatz löschen" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self deleteEventWithName:event.name];
        }];
        
        [alert addAction:confirm];
        [alert addAction:cancel];
        [self presentViewController:alert animated:YES completion:nil];
    }
}



/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}


@end
