//
//  TaskSelectorTable.m
//  EncadDatabaseController
//
//  Created by Bernd Fecht (encad-consulting.de) on 08.01.15.
//  Copyright (c) 2015 Bernd Fecht (encad-consulting.de). All rights reserved.
//

#import "TaskSelectorTable.h"
#import "TaskCell.h"
#import "Events.h"
#import "AppDelegate.h"
#import "EncadAkademie.h"

@interface TaskSelectorTable ()<UITableViewDelegate, UITableViewDataSource>{
    AppDelegate *_delegate;
}

@property (strong) NSArray *taskLabelTexts;
@property (strong) NSArray *segueIdentifiers;
@property (weak, nonatomic) IBOutlet UILabel *serverPfadTF;

- (IBAction)editServerPath:(id)sender;



@end

@implementation TaskSelectorTable

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
    
    _delegate = (AppDelegate*) [[UIApplication sharedApplication]delegate];
    
    self.taskLabelTexts = @[@"Schulungen",@"Veranstaltungen",@"Webinare",@"encad-akademie.de"];
    self.segueIdentifiers= @[@"auditionSegue",@"eventSegue",@"webinarSegue",@"webSegue"];
    
    UIImageView *tempImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"launch1136blurbot.png"]];
    [tempImageView setFrame:self.tableView.frame];
    [tempImageView setContentMode:UIViewContentModeScaleAspectFill];
    
    self.tableView.backgroundView = tempImageView;
    
    [self setServerPfadTFText];
}

-(void)setServerPfadTFText{
    if([[NSUserDefaults standardUserDefaults] stringForKey:@"serverPath"]!=nil){
        self.serverPfadTF.text=[@"ServerPfad: " stringByAppendingString:[[NSUserDefaults standardUserDefaults] stringForKey:@"serverPath"]];
    }
    else{
        self.serverPfadTF.text=@"ServerPfad: Kein Eintrag! Sie müssen einen Server-Pfad angeben!";
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:YES];
    
    [self checkForServerPath];
}

-(void)checkForServerPath{
    if([[NSUserDefaults standardUserDefaults] stringForKey:@"serverPath"]==nil){
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Server Pfad" message:@"Bitte geben Sie den Server-Pfad zu dem Ordner JsonExchange ein. Beispiel: 'http://www.encad-akademie.de'." preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder=@"Server-Pfad (ohne /JsonExchange)";
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(alertTextFieldDidChange:)
                                                         name:UITextFieldTextDidChangeNotification
                                                       object:textField];
        }];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Abbrechen" style:UIAlertActionStyleCancel handler:nil];
        
        UIAlertAction *ok =[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            UITextField *serverPathTF = alert.textFields.firstObject;
            
            NSString *serverPathString = [NSString stringWithFormat:@"%@/JsonExchange/",serverPathTF.text];
            [[NSUserDefaults standardUserDefaults] setObject:serverPathString forKey:@"serverPath"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self setServerPfadTFText];
            [_delegate runScriptOperationsWithWait];
            
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                            name:UITextFieldTextDidChangeNotification
                                                          object:nil];
        }];
        
        ok.enabled=NO;
        [alert addAction:cancelAction];
        [alert addAction:ok];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)alertTextFieldDidChange:(NSNotification *)notification
{
    UIAlertController *alertController = (UIAlertController *)self.presentedViewController;
    if (alertController)
    {
        UITextField *serverPathTF = alertController.textFields.firstObject;
        UIAlertAction *ok = alertController.actions.lastObject;
        ok.enabled = serverPathTF.text.length > 13;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.taskLabelTexts.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = @"taskCell";
    TaskCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    [cell.taskLabel setText:self.taskLabelTexts[indexPath.row]];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if([[NSUserDefaults standardUserDefaults] stringForKey:@"serverPath"]==nil){
        [self checkForServerPath];
    }
    else{
        [self performSegueWithIdentifier:self.segueIdentifiers[indexPath.row] sender:self];
    }
}


- (IBAction)editServerPath:(id)sender {
    if([[NSUserDefaults standardUserDefaults] stringForKey:@"serverPath"]==nil){
        [self checkForServerPath];
    }
    else{
        NSString *message = [NSString stringWithFormat:@"Bitte geben Sie den neuen Server-Pfad zu dem Ordner JsonExchange ein. Beispiel: 'http://www.encad-akademie.de'.\n\nAktueller Pfad: %@",[[NSUserDefaults standardUserDefaults] stringForKey:@"serverPath"]];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Server Pfad ändern" message:message preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder=@"Server-Pfad (ohne /JsonExchange)";
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(alertTextFieldDidChange:)
                                                         name:UITextFieldTextDidChangeNotification
                                                       object:textField];
        }];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Abbrechen" style:UIAlertActionStyleCancel handler:nil];
        
        UIAlertAction *ok =[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            UITextField *serverPathTF = alert.textFields.firstObject;
            
            NSString *serverPathString = [NSString stringWithFormat:@"%@/JsonExchange/",serverPathTF.text];
            [[NSUserDefaults standardUserDefaults] setObject:serverPathString forKey:@"serverPath"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self setServerPfadTFText];
            [_delegate runScriptOperationsWithWait];
            
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                            name:UITextFieldTextDidChangeNotification
                                                          object:nil];
        }];
        ok.enabled=NO;
        [alert addAction:cancelAction];
        [alert addAction:ok];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([[segue identifier]isEqualToString:@"webSegue"]){
        EncadAkademie *vc = [segue destinationViewController];
        vc.loadURL=[NSURL URLWithString:@"http://www.encad-akademie.de"];
        vc.siteName=@"www.encad-akademie.de";
    }
}


@end
