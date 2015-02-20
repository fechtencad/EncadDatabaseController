//
//  WebinarCreator.m
//  EncadDatabaseController
//
//  Created by Bernd Fecht (encad-consulting.de) on 20.02.15.
//  Copyright (c) 2015 Bernd Fecht (encad-consulting.de). All rights reserved.
//

#import "WebinarCreator.h"
#import <CoreData/CoreData.h>
#import "AppDelegate.h"
#import "Webinar.h"

@interface WebinarCreator ()<UITextFieldDelegate,
NSFetchedResultsControllerDelegate>{
    AppDelegate *_delegate;
    NSFetchedResultsController *_fetchedResultController;
}
@property (weak, nonatomic) IBOutlet UITextField *titleTF;
@property (weak, nonatomic) IBOutlet UITextField *dateTF;
@property (weak, nonatomic) IBOutlet UITextField *startTimeTF;
@property (weak, nonatomic) IBOutlet UITextField *endTimeTF;
@property (weak, nonatomic) IBOutlet UITextField *linkTF;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

- (IBAction)checkInserts:(id)sender;
- (IBAction)pressedCancelButton:(id)sender;
- (IBAction)pressedDoneButton:(id)sender;

@property (nonatomic, strong) NSSortDescriptor *theDescriptor;
@property (nonatomic, strong) UIDatePicker *startTimePicker;
@property (nonatomic, strong) UIDatePicker *endTimePicker;
@property (nonatomic, strong) UIDatePicker *datePicker;
@property (nonatomic, strong) UITextField *activeTextField;
@property (weak, nonatomic) IBOutlet UIToolbar *accViewToolbar;
@property BOOL nameIsValid;
@property BOOL editMode;

@end

@implementation WebinarCreator

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //set delegates
    _titleTF.delegate=self;
    _dateTF.delegate=self;
    _startTimeTF.delegate=self;
    _endTimeTF.delegate=self;
    _linkTF.delegate=self;
    
    //get database entrys
    _delegate = (AppDelegate*) [[UIApplication sharedApplication]delegate];
    self.theDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    
    [self initCoreDataFetch];
    
    //Configure pickers
    _startTimePicker = [[UIDatePicker alloc]init];
    [_startTimePicker setDatePickerMode:UIDatePickerModeTime];
    _startTimePicker.backgroundColor = [UIColor whiteColor];
    [_startTimePicker addTarget:self action:@selector(didSelectStartTimeFromTimePicker:) forControlEvents:UIControlEventValueChanged];
    [_startTimeTF setInputView:_startTimePicker];
    
    _endTimePicker = [[UIDatePicker alloc]init];
    [_endTimePicker setDatePickerMode:UIDatePickerModeTime];
    _endTimePicker.backgroundColor = [UIColor whiteColor];
    [_endTimePicker addTarget:self action:@selector(didSelectEndTimeFromTimePicker:) forControlEvents:UIControlEventValueChanged];
    [_endTimeTF setInputView:_endTimePicker];
    
    _datePicker = [[UIDatePicker alloc]init];
    [_datePicker setDatePickerMode:UIDatePickerModeDate];
    _datePicker.backgroundColor = [UIColor whiteColor];
    [_datePicker addTarget:self action:@selector(didSelectDateFromDatePicker:) forControlEvents:UIControlEventValueChanged];
    [self.dateTF setInputView:_datePicker];
    
    //set AccessoryView
    _titleTF.inputAccessoryView=_accViewToolbar;
    _dateTF.inputAccessoryView=_accViewToolbar;
    _startTimeTF.inputAccessoryView=_accViewToolbar;
    _endTimeTF.inputAccessoryView=_accViewToolbar;
    _linkTF.inputAccessoryView=_accViewToolbar;
    
    //set BOOL flag
    self.nameIsValid=false;
    
    //Activity Indicator settings
    [self.activityIndicator setHidden:YES];
    [self.activityIndicator setColor:[UIColor purpleColor]];
    
    //title
    self.navigationItem.title=@"Webinar erstellen";

    //Edit Mode?
    [self checkIfEditAndFillTFsAndConfigurePickers];

}


-(void)checkIfEditAndFillTFsAndConfigurePickers{
    if(_webinar){
        _editMode=true;
        _nameIsValid=true;
        _titleTF.text=_webinar.name;
        _dateTF.text=[self convertDateString:_webinar.datum];
        NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
        [formatter setDateFormat:@"EE, dd. MMMM yyyy"];
        [formatter setDateFormat:@"yyyy-MM-dd"];
        NSDate *date = [formatter dateFromString:_webinar.datum];
        [_datePicker setDate:date];
        _startTimeTF.text=_webinar.start_zeit;
        _endTimeTF.text=_webinar.end_zeit;
        _linkTF.text=_webinar.link;
        
        NSString *startTimeString = [[_webinar.start_zeit componentsSeparatedByString:@" "] objectAtIndex:0];
        NSString *endTimeString = [[_webinar.end_zeit componentsSeparatedByString:@" "] objectAtIndex:0];
        
        [formatter setDateFormat:@"HH:mm"];
        
        [_startTimePicker setDate:[formatter dateFromString:startTimeString]];
        [_endTimePicker setDate:[formatter dateFromString:endTimeString]];
    }
    else{
        _editMode=false;
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

-(NSString*)convertDateString:(NSString*)dateString{
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSDate *convertedDate= [formatter dateFromString:dateString];
    [formatter setDateFormat:@"EE, dd. MMMM yyyy"];
    return [formatter stringFromDate:convertedDate];
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


-(void)didSelectStartTimeFromTimePicker:(UIDatePicker*)datePicker{
    NSDateFormatter *theFormatter = [[NSDateFormatter alloc]init];
    [theFormatter setDateFormat:@"HH:mm"];
    NSDate *time = [datePicker date];
    NSString *timeString = [NSString stringWithFormat:@"%@ Uhr",[theFormatter stringFromDate:time]];
    _startTimeTF.text=timeString;
}

-(void)didSelectEndTimeFromTimePicker:(UIDatePicker*)datePicker{
    NSDateFormatter *theFormatter = [[NSDateFormatter alloc]init];
    [theFormatter setDateFormat:@"HH:mm"];
    NSDate *time = [datePicker date];
    NSString *timeString = [NSString stringWithFormat:@"%@ Uhr",[theFormatter stringFromDate:time]];
    _endTimeTF.text=timeString;
}

-(void)didSelectDateFromDatePicker:(UIDatePicker*)datePicker{
    NSDateFormatter *theFormatter = [[NSDateFormatter alloc]init];
    [theFormatter setDateFormat:@"EE, dd. MMMM yyyy"];
    NSDate *startDate = [datePicker date];
    NSString *dateString = [theFormatter stringFromDate:startDate];
    _dateTF.text=dateString;
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
    for(Webinar *webinar in fetchedData){
        if([webinar.name isEqualToString:self.titleTF.text]){
            [self showWrongNameAlert];
            self.titleTF.backgroundColor=[UIColor redColor];
            return false;
        }
    }
    if(self.titleTF.text.length > 0){
        self.titleTF.backgroundColor = [UIColor greenColor];
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
    if(textField == self.endTimeTF || textField == self.linkTF){
        [self pushViewUp];
    }
    if(textField==self.dateTF){
        NSDateFormatter *theFormatter = [[NSDateFormatter alloc]init];
        [theFormatter setDateFormat:@"EE, dd. MMMM yyyy"];
        NSDate *startDate = [_datePicker date];
        textField.text = [theFormatter stringFromDate:startDate];
    }
}

-(void)textFieldDidEndEditing:(UITextField *)textField{
    self.activeTextField = textField;
    if(textField == self.endTimeTF || textField == self.linkTF){
        [self pushViewDown];
    }
    if(textField == self.titleTF && !_editMode){
        self.nameIsValid = [self checkIfNameIsUsedAndColorIfNot];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)checkInserts:(id)sender {
    [self.activityIndicator setHidden:NO];
    [self.activityIndicator startAnimating];
    if(self.nameIsValid){
        if(self.titleTF.text.length && self.dateTF.text.length && self.startTimeTF.text.length && self.endTimeTF.text.length && self.linkTF.text.length > 0){
            NSString *message = [NSString stringWithFormat:@"\nVeranstaltungsname: %@\nDatum: %@\nStartzeit: %@\nEndzeit: %@ \nLink: %@\n\n",self.titleTF.text,self.dateTF.text,self.startTimeTF.text,self.endTimeTF.text,self.linkTF.text];
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
    [self deleteIfEditMode];
    //format Dates-String
    NSDateFormatter *theFormatter = [[NSDateFormatter alloc]init];
    theFormatter.dateFormat=@"EE, dd. MMMM yyyy";
    NSDate *date = [theFormatter dateFromString:self.dateTF.text];
    theFormatter.dateFormat=@"yyyy-MM-dd";
    NSString *formatedDate = [theFormatter stringFromDate:date];
    
    
    NSString *urlString =[[NSString alloc]initWithFormat:@"%@insertEventData.php?name=%@&datum=%@&start_zeit=%@&end_zeit=%@&link=%@&type=%@",[[NSUserDefaults standardUserDefaults] stringForKey:@"serverPath"] ,self.titleTF.text, formatedDate, self.startTimeTF.text,self.endTimeTF.text,self.linkTF.text,@"Webinar"];
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
    [self.webinarController reloadData];
    [self.activityIndicator stopAnimating];
    [self.activityIndicator setHidden:YES];
}

-(void)deleteIfEditMode{
    if(_editMode){
        [self deleteEventWithName:_webinar.name];
        BOOL inProgress=true;
        while(inProgress){
            inProgress=[_delegate checkForNewFileVersionOnServerByURL:[[[NSUserDefaults standardUserDefaults]stringForKey:@"serverPath" ]stringByAppendingString:@"webinar.json" ] withEntityName:@"Webinar"];
        }
    }
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
}

- (IBAction)pressedCancelButton:(id)sender {
    if(self.activeTextField!=nil){
        self.activeTextField.text=@"";
    }
    [self.activeTextField endEditing:YES];
}

- (IBAction)pressedDoneButton:(id)sender {
     [self.activeTextField endEditing:YES];
}
@end
