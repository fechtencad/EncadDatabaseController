//
//  EventCreator.m
//  EncadDatabaseController
//
//  Created by Bernd Fecht (encad-consulting.de) on 15.01.15.
//  Copyright (c) 2015 Bernd Fecht (encad-consulting.de). All rights reserved.
//

#import "EventCreator.h"
#import "AppDelegate.h"
#import <CoreData/CoreData.h>
#import "Veranstaltung.h"

@interface EventCreator ()<NSFetchedResultsControllerDelegate>{
    AppDelegate *_delegate;
    NSFetchedResultsController *_fetchedResultController;
}
@property (weak, nonatomic) IBOutlet UITextField *nameTF;
@property (weak, nonatomic) IBOutlet UITextField *startDateTF;
@property (weak, nonatomic) IBOutlet UITextField *endDateTF;
@property (weak, nonatomic) IBOutlet UITextField *timeTF;
@property (weak, nonatomic) IBOutlet UITextField *locationTF;
@property (weak, nonatomic) IBOutlet UITextField *timeAdditionTF;
@property (strong, nonatomic) IBOutlet UIToolbar *accViewToolbar;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;

@property (nonatomic, strong) NSSortDescriptor *theDescriptor;
@property (nonatomic, strong) NSString *entityName;
@property (nonatomic, strong) UIDatePicker *startDatePicker;
@property (nonatomic, strong) UIDatePicker *endDatePicker;
@property (nonatomic, strong) UIDatePicker *timePicker;
@property (nonatomic, strong) NSDate *selectedStartDate;
@property (nonatomic, strong) NSDate *selectedEndDate;
@property (nonatomic, strong) UITextField *activeTextField;
@property BOOL nameIsValid;
@property BOOL editMode;

- (IBAction)pressedCancelButton:(id)sender;
- (IBAction)pressedDoneButton:(id)sender;
- (IBAction)checkInserts:(id)sender;

@end

@implementation EventCreator

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //Set TextField Delegates
    [self.nameTF setDelegate:self];
    [self.startDateTF setDelegate:self];
    [self.endDateTF setDelegate:self];
    [self.timeTF setDelegate:self];
    [self.locationTF setDelegate:self];
    [self.timeAdditionTF setDelegate:self];
    
    
    //Get Database entrys
    _entityName=@"Veranstaltung";
    _delegate = (AppDelegate*) [[UIApplication sharedApplication]delegate];
    self.theDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    
    [self initCoreDataFetch];
    
    
    //Configure pickers
    _startDatePicker = [[UIDatePicker alloc]init];
    [_startDatePicker setDatePickerMode:UIDatePickerModeDate];
    _startDatePicker.backgroundColor = [UIColor whiteColor];
    [_startDatePicker addTarget:self action:@selector(didSelectStartDateFromDatePicker:) forControlEvents:UIControlEventValueChanged];
    [self.startDateTF setInputView:_startDatePicker];
    
    _endDatePicker = [[UIDatePicker alloc]init];
    [_endDatePicker setDatePickerMode:UIDatePickerModeDate];
    _endDatePicker.backgroundColor = [UIColor whiteColor];
    [_endDatePicker addTarget:self action:@selector(didSelectEndDateFromDatePicker:) forControlEvents:UIControlEventValueChanged];
    [self.endDateTF setInputView:_endDatePicker];
    
    _timePicker = [[UIDatePicker alloc]init];
    [_timePicker setDatePickerMode:UIDatePickerModeTime];
    _timePicker.backgroundColor = [UIColor whiteColor];
    [_timePicker addTarget:self action:@selector(didSelectTimeFromTimePicker:) forControlEvents:UIControlEventValueChanged];
    [self.timeTF setInputView:_timePicker];
    
    //set AccessoryView
    self.nameTF.inputAccessoryView=self.accViewToolbar;
    self.startDateTF.inputAccessoryView=self.accViewToolbar;
    self.endDateTF.inputAccessoryView=self.accViewToolbar;
    self.timeTF.inputAccessoryView=self.accViewToolbar;
    self.locationTF.inputAccessoryView=self.accViewToolbar;
    self.timeAdditionTF.inputAccessoryView=self.accViewToolbar;
    
    //set BOOl Flag
    self.nameIsValid=false;
    self.editMode=false;
    
    //Activity Indicator settings
    [self.activityIndicator setHidden:YES];
    [self.activityIndicator setColor:[UIColor purpleColor]];
    
    //title
    self.navigationItem.title=self.entityName;
    
    //check for edit
    [self checkForEditModeAndFillTFs];
    
}


-(void)checkForEditModeAndFillTFs{
    if(_event){
        _editMode=true;
        self.nameTF.text=_event.name;
        self.startDateTF.text= [self convertDateString:_event.anfangs_datum];
        self.endDateTF.text= [self convertDateString:_event.end_datum];
        NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
        [formatter setDateFormat:@"yyyy-MM-dd"];
        NSDate *startDate = [formatter dateFromString:_event.anfangs_datum];
        [_startDatePicker setDate:startDate];
        NSDate *endDate = [formatter dateFromString:_event.end_datum];
        [_endDatePicker setDate:endDate];
        
        NSArray *stringComponents = [_event.uhrzeit componentsSeparatedByString:@" "];
        
        _timeTF.text=[NSString stringWithFormat:@"%@ %@",stringComponents[0],stringComponents[1]];
        
        _timeAdditionTF.text=[[_event.uhrzeit componentsSeparatedByString:@"Uhr"]objectAtIndex:1];
        
        _locationTF.text=_event.ort;
        
        NSString *timeString = [[_event.uhrzeit componentsSeparatedByString:@" "] objectAtIndex:0];
        [formatter setDateFormat:@"HH:mm"];
        
        [_timePicker setDate:[formatter dateFromString:timeString]];

    }
}

-(NSString*)convertDateString:(NSString*)dateString{
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSDate *convertedDate= [formatter dateFromString:dateString];
    [formatter setDateFormat:@"EE, dd. MMMM yyyy"];
    return [formatter stringFromDate:convertedDate];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    NSEntityDescription *theType = [NSEntityDescription entityForName:_entityName inManagedObjectContext:_delegate.managedObjectContext];
    theFetch.entity = theType;
    theFetch.sortDescriptors = @[self.theDescriptor];
    return theFetch;
}


-(void)didSelectStartDateFromDatePicker:(UIDatePicker*)datePicker{
    NSDateFormatter *theFormatter = [[NSDateFormatter alloc]init];
    [theFormatter setDateFormat:@"EE, dd. MMMM yyyy"];
    NSDate *startDate = [datePicker date];
    NSString *dateString = [theFormatter stringFromDate:startDate];
    [self.startDateTF setText:dateString];
    
    self.selectedStartDate = startDate;
}

-(void)didSelectEndDateFromDatePicker:(UIDatePicker*)datePicker{
    NSDateFormatter *theFormatter = [[NSDateFormatter alloc]init];
    [theFormatter setDateFormat:@"EE, dd. MMMM yyyy"];
    NSDate *endDate = [datePicker date];
    NSString *dateString = [theFormatter stringFromDate:endDate];
    [self.endDateTF setText:dateString];
    
    self.selectedEndDate = endDate;
}

-(void)didSelectTimeFromTimePicker:(UIDatePicker*)datePicker{
    NSDateFormatter *theFormatter = [[NSDateFormatter alloc]init];
    [theFormatter setDateFormat:@"HH:mm"];
    NSDate *time = [datePicker date];
    NSString *timeString = [NSString stringWithFormat:@"%@ Uhr",[theFormatter stringFromDate:time]];
    [self.timeTF setText:timeString];
}

//Push view
-(void)pushViewDown{
    [self.view setFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    
}
//Push view
-(void)pushViewUp{
    [self.view setFrame:CGRectMake(0, -200.0, self.view.bounds.size.width, self.view.bounds.size.height)];
    
}

-(BOOL)checkIfNameIsUsedAndColorIfNot{
    NSArray *fetchedData = [_fetchedResultController fetchedObjects];
    if([self.entityName isEqualToString:@"Veranstaltung"]){
        for(Veranstaltung *event in fetchedData){
            if([event.name isEqualToString:self.nameTF.text]){
                [self showWrongNameAlert];
                self.nameTF.backgroundColor=[UIColor redColor];
                return false;
            }
        }
    }
    if(self.nameTF.text.length > 0){
        self.nameTF.backgroundColor = [UIColor greenColor];
    }    
    return true;
}

-(void)showWrongNameAlert{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Name existiert bereits" message:@"Es existiert bereits ein Event mit diesem Namen! Ein Event muss einen eindeutigen Namen besitzen, um in der Datenbank verifiziert zu werden!" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}


#pragma mark - TextField Delegates

-(void)textFieldDidBeginEditing:(UITextField *)textField{
    self.activeTextField = textField;
    if(textField == self.timeTF || textField == self.timeAdditionTF || textField == self.locationTF){
        [self pushViewUp];
    }
    if(textField==self.startDateTF){
        NSDateFormatter *theFormatter = [[NSDateFormatter alloc]init];
        [theFormatter setDateFormat:@"EE, dd. MMMM yyyy"];
        NSDate *startDate = [_startDatePicker date];
        textField.text = [theFormatter stringFromDate:startDate];
        self.selectedStartDate=startDate;
    }
    if(textField==self.endDateTF){
        NSDateFormatter *theFormatter = [[NSDateFormatter alloc]init];
        [theFormatter setDateFormat:@"EE, dd. MMMM yyyy"];
        NSDate *endDate = [_endDatePicker date];
        textField.text = [theFormatter stringFromDate:endDate];
        self.selectedEndDate=endDate;
    }
}

-(void)textFieldDidEndEditing:(UITextField *)textField{
    if(textField == self.timeTF || textField == self.timeAdditionTF || textField == self.locationTF){
        [self pushViewDown];
    }
    if(textField == self.nameTF){
        self.nameIsValid = [self checkIfNameIsUsedAndColorIfNot];
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

- (IBAction)pressedCancelButton:(id)sender {
    if(self.activeTextField!=nil){
        self.activeTextField.text=@"";
    }
    [self.activeTextField endEditing:YES];
}

- (IBAction)pressedDoneButton:(id)sender {
    [self.activeTextField endEditing:YES];
}

- (IBAction)checkInserts:(id)sender {
    [self.activityIndicator setHidden:NO];
    [self.activityIndicator startAnimating];
    if(self.nameIsValid || self.editMode){
        if(self.nameTF.text.length && self.startDateTF.text.length && self.endDateTF.text.length && self.timeTF.text.length > 0){
            NSString *message = [NSString stringWithFormat:@"\nVeranstaltungsname: %@\nStart-Datum: %@\nEnd-Datum: %@\nUhrzeit: %@ Uhr\nUhrzeit-Anmerkung: %@\nStadt: %@\n\n",self.nameTF.text,self.startDateTF.text,self.endDateTF.text,self.timeTF.text,self.timeAdditionTF.text,self.locationTF.text];
              message = [message stringByAppendingString:@"Stimmen Ihre Angaben überein? Wenn ja klicken Sie auf 'Datenbankeintrag erstellen'."];
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Veranstaltung überprüfen" message:message preferredStyle:UIAlertControllerStyleAlert];
            
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
    else{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Name existiert bereits!" message:@"Es existiert bereits ein Event mit diesem Namen! Ein Event muss einen eindeutigen Namen besitzen, um in der Datenbank verifiziert zu werden!" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
        
        [alert addAction:cancelAction];
        [self presentViewController:alert animated:YES completion:nil];
        [self.activityIndicator stopAnimating];
        [self.activityIndicator setHidden:YES];
    }
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
}

-(void)createDatabaseEntry{
    //clear if edit
    [self deleteIfEditMode];
    //format Dates-String
    NSDateFormatter *theFormatter = [[NSDateFormatter alloc]init];
    theFormatter.dateFormat=@"EE, dd. MMMM yyyy";
    NSDate *startDate = [theFormatter dateFromString:self.startDateTF.text];
    NSDate *endDate = [theFormatter dateFromString:self.endDateTF.text];
    theFormatter.dateFormat=@"yyyy-MM-dd";
    NSString *formatedStartDate = [theFormatter stringFromDate:startDate];
    NSString *formatedEndDate = [theFormatter stringFromDate:endDate];
    
    //format Clock-String
    NSString *formatedTimeString = [NSString stringWithFormat:@"%@ %@",self.timeTF.text, self.timeAdditionTF.text];
    
    
    NSString *urlString =[[NSString alloc]initWithFormat:@"%@insertEventData.php?name=%@&ort=%@&anfangs_datum=%@&end_datum=%@&uhrzeit=%@&type=%@",[[NSUserDefaults standardUserDefaults] stringForKey:@"serverPath"] ,self.nameTF.text, self.locationTF.text, formatedStartDate,formatedEndDate,formatedTimeString,self.entityName];
    NSURL *url = [[NSURL alloc]initWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    
    NSURLRequest *request = [[NSURLRequest alloc]initWithURL:url];
    
    NSURLResponse *response;
    NSError *error;
    
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    UIAlertAction *dismiss = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
    if(error){
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Dankankeintrag fehlgeschlagen" message:@"Der Daten-Upload ist fehlgeschlagen! Bitte informieren Sie den Administrator dieser App!" preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:dismiss];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else{
        NSLog(@"Created entity for URL-Request: %@",urlString);
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Dankankeintrag erfolgreich" message:@"Der Daten-Upload war erfolgreich!" preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:dismiss];
        [self presentViewController:alert animated:YES completion:nil];
    }
    [self.eventController reloadData];
    [self.activityIndicator stopAnimating];
    [self.activityIndicator setHidden:YES];
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
}

-(void)deleteIfEditMode{
    if(_editMode){
        [self deleteEventWithName:_event.name];
        BOOL inProgress=true;
        while(inProgress){
            inProgress=[_delegate checkForNewFileVersionOnServerByURL:[[[NSUserDefaults standardUserDefaults]stringForKey:@"serverPath" ]stringByAppendingString:@"event.json" ] withEntityName:@"Veranstaltung"];
        }
        //wait for server
        [NSThread sleepForTimeInterval:3.0];
    }
}
         
         

@end
