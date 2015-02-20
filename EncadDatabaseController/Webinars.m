//
//  Webinars.m
//  EncadDatabaseController
//
//  Created by Bernd Fecht (encad-consulting.de) on 19.02.15.
//  Copyright (c) 2015 Bernd Fecht (encad-consulting.de). All rights reserved.
//

#import "Webinars.h"
#import <CoreData/CoreData.h>
#import "AppDelegate.h"
#import "WebinarCell.h"
#import "Webinar.h"
#import "WebinarCreator.h"
#import "EncadAkademie.h"

@interface Webinars ()<NSFetchedResultsControllerDelegate>{
    AppDelegate *_delegate;
    NSFetchedResultsController *_fetchedResultController;
}

@property (nonatomic, strong) NSSortDescriptor *theDescriptor;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
- (IBAction)pressedLinkButton:(UIButton *)sender;

@end

@implementation Webinars

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //set core data
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
    
    //set title
    self.navigationItem.title=@"Webinare";

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
    NSEntityDescription *theType = [NSEntityDescription entityForName:@"Webinar" inManagedObjectContext:_delegate.managedObjectContext];
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

-(NSString*)convertDateString:(NSString*)dateString{
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSDate *convertedDate= [formatter dateFromString:dateString];
    [formatter setDateFormat:@"dd.MM.yyyy"];
    return [formatter stringFromDate:convertedDate];
}

-(void)deleteEventWithName:(NSString*)eventName{
    NSString *urlString =[[NSString alloc]initWithFormat:@"%@deleteEventData.php?name=%@&type=%@",[[NSUserDefaults standardUserDefaults] stringForKey:@"serverPath"],eventName,@"Webinar"];
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
    [_delegate runWebinarScriptsWithWait];
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    
    Webinar *webinar = [_fetchedResultController objectAtIndexPath:indexPath];
    
    static NSString *identifier = @"webinarCell";
    WebinarCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    
    // Configure the cell...
    
    cell.titleLabel.text=webinar.name;
    cell.dateLabel.text=[self convertDateString:webinar.datum];
    cell.startTimeLabel.text=webinar.start_zeit;
    cell.endTimeLabel.text=webinar.end_zeit;
    [cell.linkButton setTitle:webinar.link forState:UIControlStateNormal];
    
    return cell;
}



// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Webinar *webinar = [_fetchedResultController objectAtIndexPath:indexPath];
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self deleteEventWithName:webinar.name];
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    Webinar *webinar = [_fetchedResultController objectAtIndexPath:indexPath];
    
    WebinarCreator *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"webinarCreator"];
    vc.webinar=webinar;
    vc.webinarController=self;
    
    [self.navigationController pushViewController:vc animated:YES];
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
    if([segue.identifier isEqualToString:@"webinarCreatorSegue"]){
        WebinarCreator *vc = [segue destinationViewController];
        vc.webinarController=self;
    }
}



- (IBAction)pressedLinkButton:(UIButton *)sender {
    NSString *urlString = sender.titleLabel.text;
    NSURL *url = [NSURL URLWithString:urlString];
    
    EncadAkademie *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"universalWebView"];
    vc.loadURL=url;
    
    [self.navigationController pushViewController:vc animated:YES];
}
@end
