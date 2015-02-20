//
//  Auditions.m
//  EncadDatabaseController
//
//  Created by Bernd Fecht (encad-consulting.de) on 12.01.15.
//  Copyright (c) 2015 Bernd Fecht (encad-consulting.de). All rights reserved.
//

#import "Auditions.h"
#import <CoreData/CoreData.h>
#import "AppDelegate.h"
#import "Schulungstermin.h"
#import "AuditionCell.h"
#import "AuditionCreator.h"


@interface Auditions ()<NSFetchedResultsControllerDelegate>{
    AppDelegate *_delegate;
    NSFetchedResultsController *_fetchedResultController;
}

@property (nonatomic, strong) NSSortDescriptor *theDescriptor;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

@end

@implementation Auditions

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    _delegate = (AppDelegate*) [[UIApplication sharedApplication]delegate];
    self.theDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"datum" ascending:YES];
    
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
    NSEntityDescription *theType = [NSEntityDescription entityForName:@"Schulungstermin" inManagedObjectContext:_delegate.managedObjectContext];
    theFetch.entity = theType;
    theFetch.sortDescriptors = @[self.theDescriptor];
    return theFetch;
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



-(void)deleteAuditionWithID:(NSString*)ID{
    long deleteID = [ID integerValue];
    NSString *urlString =[[NSString alloc]initWithFormat:@"%@deleteAuditData.php?id=%ld",[[NSUserDefaults standardUserDefaults] stringForKey:@"serverPath"] ,deleteID];
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
    [_delegate runSchulungsterminScriptsWithWait];
    
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
    AuditionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"auditionCell" forIndexPath:indexPath];
    
    Schulungstermin *schulung = [_fetchedResultController objectAtIndexPath:indexPath];
    cell.name.text= schulung.schulungs_name;
    cell.date.text=[self convertDateString:schulung.datum WithDaysToAdd:[schulung.dauer integerValue]];
    cell.city.text=schulung.orts_name;
    
    return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    Schulungstermin *schulung = [_fetchedResultController objectAtIndexPath:indexPath];
    NSString *msg = [NSString stringWithFormat:@"ID: %@\r\nName: %@\r\nDatum: %@\r\nDauer: %@ Tage\r\nOrt: %@\r\n",schulung.id, schulung.schulungs_name,[self convertDateString:schulung.datum],schulung.dauer, schulung.orts_name];
    UIAlertController *informer = [UIAlertController alertControllerWithTitle:@"Details" message:msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
    [informer addAction:ok];
    [self presentViewController:informer animated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.spinner startAnimating];
    [self.spinner setHidden:NO];
    Schulungstermin *schulung = [_fetchedResultController objectAtIndexPath:indexPath];
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *convertedDateString =[self convertDateString:schulung.datum];
        NSString *message;
        NSString *title;
        if([self dateIsOld:schulung.datum]){
            message = [NSString stringWithFormat:@"\nSind Sie sicher, dass Sie den Schulungstermin '%@' am '%@' in '%@' löschen wollen?",schulung.schulungs_name,convertedDateString,schulung.orts_name];
            title = @"Löschen (alter Datensatz)";
        }
        else{
            message = [NSString stringWithFormat:@"\nSind Sie sicher, dass Sie den aktuellen Schulungstermin '%@' am '%@' in '%@' löschen wollen? Bei Fehlverhalten könnten schwerwiegende Konsequenzen entstehen!",schulung.schulungs_name,convertedDateString,schulung.orts_name];
            title = @"Löschen (aktueller Datensatz)";
        }
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Nein, Abbrechen" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [self.spinner stopAnimating];
            [self.spinner setHidden:YES];
        }];
        
        UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"Ja, Datensatz löschen" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self deleteAuditionWithID:schulung.id];
        }];
        
        [alert addAction:confirm];
        [alert addAction:cancel];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    Schulungstermin *schulung = [_fetchedResultController objectAtIndexPath:indexPath];
    NSString *msg = [NSString stringWithFormat:@"ID: %@\r\nName: %@\r\nDatum: %@\r\nDauer: %@ Tage\r\nOrt: %@\r\n",schulung.id, schulung.schulungs_name,[self convertDateString:schulung.datum],schulung.dauer, schulung.orts_name];
    UIAlertController *informer = [UIAlertController alertControllerWithTitle:@"Details" message:msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
    [informer addAction:ok];
    [self presentViewController:informer animated:YES completion:nil];
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
    if([[segue identifier]isEqualToString:@"createAuditSegue"]){
        AuditionCreator *creator = segue.destinationViewController;
        creator.auditionsController=self;
    }
}


@end
