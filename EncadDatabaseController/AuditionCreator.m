//
//  AuditionCreator.m
//  EncadDatabaseController
//
//  Created by Bernd Fecht (encad-consulting.de) on 08.01.15.
//  Copyright (c) 2015 Bernd Fecht (encad-consulting.de). All rights reserved.
//

#import "AuditionCreator.h"
#import <CoreData/CoreData.h>
#import "AppDelegate.h"
#import "Schulung.h"


@interface AuditionCreator ()<NSFetchedResultsControllerDelegate>{
    AppDelegate *_delegate;
    NSFetchedResultsController *_fetchedResultController;
}

@property (weak, nonatomic) IBOutlet UITextField *auditTextField;
@property (weak, nonatomic) IBOutlet UITextField *dateTextField;
@property (weak, nonatomic) IBOutlet UIToolbar *inputAccViewToolBar;
@property (weak, nonatomic) IBOutlet UITextField *addTextField;
@property (weak, nonatomic) IBOutlet UITextField *endDateTextField;
@property (weak, nonatomic) IBOutlet UISegmentedControl *citySegmentControll;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (nonatomic, strong)Schulung *selectedSchulung;
@property (nonatomic, strong) NSFetchRequest *fetchRequest;
@property (nonatomic, strong) NSDate *selectedDate;
@property (nonatomic, strong) UITextField *activeTextField;
@property (nonatomic, strong) UIPickerView *picker;
@property (nonatomic, strong) UIDatePicker *datePicker;
@property BOOL editMode;
@property NSInteger daysToAddInEditMode;


- (IBAction)cancelPicker:(id)sender;
- (IBAction)donePicker:(id)sender;
- (IBAction)checkInserts:(id)sender;

@property (nonatomic, strong) NSSortDescriptor *theDescriptor;

@end

@implementation AuditionCreator

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    _delegate = (AppDelegate*) [[UIApplication sharedApplication]delegate];
    self.theDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    
    [self initCoreDataFetch];
    
    [self.auditTextField setDelegate:self];
    [self.dateTextField setDelegate:self];
    [self.endDateTextField setDelegate:self];
    [self.addTextField setDelegate:self];
    _picker = [[UIPickerView alloc]init];
    [_picker setDelegate:self];
    [_picker setDataSource:self];
    _picker.backgroundColor = [UIColor whiteColor];
    [self.auditTextField setInputView:_picker];
    
    _datePicker = [[UIDatePicker alloc]init];
    [_datePicker setDatePickerMode:UIDatePickerModeDate];
    _datePicker.backgroundColor = [UIColor whiteColor];
    [_datePicker addTarget:self action:@selector(didSelectDateFromDatePicker:) forControlEvents:UIControlEventValueChanged];
    [self.dateTextField setInputView:_datePicker];
    
    
    self.auditTextField.inputAccessoryView = self.inputAccViewToolBar;
    self.dateTextField.inputAccessoryView = self.inputAccViewToolBar;
    
    [self.activityIndicator setHidden:YES];
    [self.activityIndicator setColor:[UIColor purpleColor]];
    
    //set bool flag
    _editMode=false;
    
    //check for edit mode
    [self checkForEditModeAndFillTFs];
}

-(void)checkForEditModeAndFillTFs{
    if(_audition){
        _editMode=true;
        _auditTextField.text=_audition.schulungs_name;
        _auditTextField.enabled=false;
        _dateTextField.text = [self convertDateString:_audition.datum];
        _endDateTextField.text= [self convertDateString:_audition.datum WithDaysToAdd:[_audition.dauer integerValue]];
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
        [formatter setDateFormat:@"yyyy-MM-dd"];
        NSDate *startDate = [formatter dateFromString:_audition.datum];
        [_datePicker setDate:startDate];
        
        _daysToAddInEditMode=[_audition.dauer integerValue];
        
        if([_audition.orts_name isEqualToString:@"Augsburg"]){
            [_citySegmentControll setSelectedSegmentIndex:0];
        }
        else{
            [_citySegmentControll setSelectedSegmentIndex:1];
        }
    }
}

-(NSString*)convertDateString:(NSString*)dateString{
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSDate *convertedDate= [formatter dateFromString:dateString];
    [formatter setDateFormat:@"EE, dd. MMMM yyyy"];
    return [formatter stringFromDate:convertedDate];
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
    [theFormatter setDateFormat:@"EE, dd. MMMM yyyy"];
    NSString *convertedDateString = [theFormatter stringFromDate:endDate];
    return convertedDateString;
}

-(void)textFieldDidBeginEditing:(UITextField *)textField{
    self.activeTextField = textField;
    if(textField==self.auditTextField){
        Schulung *schulung = [_fetchedResultController objectAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
        textField.text=schulung.name;
        self.addTextField.text=schulung.zusatz;
        self.selectedSchulung=schulung;
    }
    else if(textField==self.dateTextField){
        [self pushViewUp];
        NSDateFormatter *theFormatter = [[NSDateFormatter alloc]init];
        [theFormatter setDateFormat:@"EE, dd. MMMM yyyy"];
        NSDate *startDate = [_datePicker date];
        textField.text = [theFormatter stringFromDate:startDate];
        self.selectedDate=startDate;
    }
    [self checkForCompletion];
}

-(void)textFieldDidEndEditing:(UITextField *)textField{
    if(textField==self.dateTextField){
        [self pushViewDown];
    }
}

-(void)pushViewDown{
    if([[UIScreen mainScreen]bounds].size.height == 480){
    [self.view setFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    }
}

-(void)pushViewUp{
    if([[UIScreen mainScreen]bounds].size.height == 480){
    [self.view setFrame:CGRectMake(0, -140.0, self.view.bounds.size.width, self.view.bounds.size.height)];
    }
}

-(void)didSelectDateFromDatePicker:(UIDatePicker*)datePicker{
    NSDateFormatter *theFormatter = [[NSDateFormatter alloc]init];
    [theFormatter setDateFormat:@"EE, dd. MMMM yyyy"];
    NSDate *startDate = [datePicker date];
    NSString *dateString = [theFormatter stringFromDate:startDate];
    [self.dateTextField setText:dateString];
    
    self.selectedDate = startDate;
    
    [self checkForCompletion];
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    Schulung *schulung = [_fetchedResultController objectAtIndexPath:[NSIndexPath indexPathForRow:row inSection:component]];
    [self.auditTextField setText:schulung.name];
    
    [self.addTextField setText:schulung.zusatz];
    
    self.selectedSchulung = schulung;
    
    [self checkForCompletion];
}

-(void)checkForCompletion{
    if(self.auditTextField.text.length && self.dateTextField.text.length >0){
        long daysToAdd=0;
        if(_editMode){
            daysToAdd = _daysToAddInEditMode;
        }
        else{
            daysToAdd = [self.selectedSchulung.dauer integerValue];
        }
        daysToAdd-=1;
        NSDate *endDate = [self.selectedDate dateByAddingTimeInterval:60*60*24*daysToAdd];
        NSDateFormatter *theFormatter = [[NSDateFormatter alloc]init];
        [theFormatter setDateFormat:@"EE, dd. MMMM yyyy"];
        [self.endDateTextField setText:[theFormatter stringFromDate:endDate]];
    }
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
    NSEntityDescription *theType = [NSEntityDescription entityForName:@"Schulung" inManagedObjectContext:_delegate.managedObjectContext];
    theFetch.entity = theType;
    theFetch.sortDescriptors = @[self.theDescriptor];
    return theFetch;
}

- (IBAction)cancelPicker:(id)sender {
    if(self.activeTextField != nil){
        if(self.activeTextField==self.auditTextField){
            [self.addTextField setText:@""];
        }
        [self.activeTextField setText:@""];
        [self.endDateTextField setText:@""];
    }
    [self.activeTextField endEditing:YES];
}

- (IBAction)donePicker:(id)sender {
    [self.activeTextField endEditing:YES];
}

- (IBAction)checkInserts:(id)sender {
    [self.activityIndicator setHidden:NO];
    [self.activityIndicator startAnimating];
    if(self.auditTextField.text.length && self.dateTextField.text.length && self.endDateTextField.text.length && self.endDateTextField.text.length >0){
        NSString *message = [NSString stringWithFormat:@"\nSchulung: %@\nZusatz: %@\nStart-Datum: %@\nEnd-Datum: %@\nStadt: %@\n\n",self.auditTextField.text,self.addTextField.text,self.dateTextField.text,self.endDateTextField.text,[self.citySegmentControll titleForSegmentAtIndex:self.citySegmentControll.selectedSegmentIndex]];
        message = [message stringByAppendingString:@"Stimmen Ihre Angaben überein? Wenn ja klicken Sie auf 'Datenbankeintrag erstellen'."];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Schulungstermin überprüfen" message:message preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Abbrechen" style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *sendAction = [UIAlertAction actionWithTitle:@"Datenbankeintrag erstellen" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self createDatabaseEntry];
        }];
        
        [alert addAction:cancelAction];
        [alert addAction:sendAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Fehlende Eingaben" message:@"Bitte füllen Sie alle benötigten Felder aus. Pflichtfelder sind mit einem * gekennzeichnet!" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
        
        
        [alert addAction:cancelAction];
        [self presentViewController:alert animated:YES completion:nil];
        [self.activityIndicator stopAnimating];
        [self.activityIndicator setHidden:YES];
    }
}

-(BOOL)textFieldShouldClear:(UITextField *)textField{
    if(textField==self.auditTextField){
        self.addTextField.text=@"";
        return YES;
    }
    else if(textField==self.dateTextField){
        self.endDateTextField.text=@"";
        return YES;
    }
    return NO;
}


-(void)createDatabaseEntry{
    if(_editMode){
        [self deleteIfEditMode];
    }
    NSDateFormatter *theFormatter = [[NSDateFormatter alloc]init];
    theFormatter.dateFormat=@"EE, dd. MMMM yyyy";
    NSDate *endDate = [theFormatter dateFromString:self.dateTextField.text];
    theFormatter.dateFormat=@"yyyy-MM-dd";
    NSString *formatedEndDate = [theFormatter stringFromDate:endDate];
    
    NSString *urlString =[[NSString alloc]initWithFormat:@"%@insertAuditData.php?schulungs_name=%@&orts_name=%@&datum=%@",[[NSUserDefaults standardUserDefaults] stringForKey:@"serverPath"], self.auditTextField.text, [self.citySegmentControll titleForSegmentAtIndex:self.citySegmentControll.selectedSegmentIndex],formatedEndDate];
    NSURL *url = [[NSURL alloc]initWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    NSLog(@"HTTP_POST: %@", urlString);
    
    NSURLRequest *request = [[NSURLRequest alloc]initWithURL:url];
    NSURLResponse *response;
    NSError *error;
    
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    UIAlertAction *dismiss = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
    if(error){
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Dankankeintrag fehlgeschlagen" message:@"Der Daten-Upload ist fehlgeschlagen! Bitte informieren Sie den Administrator dieser App!" preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:dismiss];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else{
        NSLog(@"connection: %@",data);
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Dankankeintrag erfolgreich" message:@"Der Daten-Upload war erfolgreich!" preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:dismiss];
        [self presentViewController:alert animated:YES completion:nil];
    }
    [self.auditionsController reloadData];
    [self.activityIndicator stopAnimating];
    [self.activityIndicator setHidden:YES];
}



-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    id sectionInfo = [[_fetchedResultController sections]objectAtIndex:component];
    return [sectionInfo numberOfObjects];
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    Schulung *schulung = [_fetchedResultController objectAtIndexPath:[NSIndexPath indexPathForRow:row inSection:component]];
    return schulung.name;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
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
}

-(void)deleteIfEditMode{
    if(_editMode){
        [self deleteAuditionWithID:_audition.id];
        BOOL inProgress=true;
        while(inProgress){
            inProgress=[_delegate checkForNewFileVersionOnServerByURL:[[[NSUserDefaults standardUserDefaults]stringForKey:@"serverPath" ]stringByAppendingString:@"allAudits.json" ] withEntityName:@"Schulungstermin"];
        }
        //wait for server
        [NSThread sleepForTimeInterval:3.0];
    }
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
