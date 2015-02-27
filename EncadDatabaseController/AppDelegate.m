//
//  AppDelegate.m
//  EncadDatabaseController
//
//  Created by Bernd Fecht (encad-consulting.de) on 08.01.15.
//  Copyright (c) 2015 Bernd Fecht (encad-consulting.de). All rights reserved.
//

#import <CoreData/CoreData.h>
#import "AppDelegate.h"
#include <unistd.h>

@interface AppDelegate ()

@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) UIStoryboard *storyboard;

- (NSURL *)persistentStoreURL;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    

    
    [self runScriptOperations];
        
    return YES;
}

-(void)runScriptOperations{
    if([[NSUserDefaults standardUserDefaults] stringForKey:@"serverPath"]  != nil){
        [self runSchulungScripts];
        
        [self runSchulungsterminScripts];
        
        [self runWebinarScripts];
        
        [self runVeranstaltungScripts];
    }
}


-(void)runScriptOperationsWithWait{
    if([[NSUserDefaults standardUserDefaults] stringForKey:@"serverPath"]  != nil){
        [self runSchulungScriptsWithWait];
    
        [self runSchulungsterminScriptsWithWait];
    
        [self runWebinarScriptsWithWait];
    
        [self runVeranstaltungScriptsWithWait];
    }
}
    
-(void)runSchulungScripts{
    NSString *jsonString = [[[NSUserDefaults standardUserDefaults] stringForKey:@"serverPath"] stringByAppendingString:@"audits.json"];
    NSString *entityName = @"Schulung";
    
    [self initDataDownloadForURLString:jsonString forEntityName:entityName checkVersion:YES];
}

-(void)runSchulungsterminScripts{
    NSString *jsonString = [[[NSUserDefaults standardUserDefaults] stringForKey:@"serverPath"]  stringByAppendingString:@"allAudits.json"];
    NSString *phpString = [[[NSUserDefaults standardUserDefaults] stringForKey:@"serverPath"]  stringByAppendingString:@"allAuditionsCreator.php"];
    NSString *entityName = @"Schulungstermin";
    
    [self runScript:phpString ];
    [self initDataDownloadForURLString:jsonString forEntityName:entityName checkVersion:NO];
}

-(void)runWebinarScripts{
    NSString *jsonString = [[[NSUserDefaults standardUserDefaults] stringForKey:@"serverPath"]  stringByAppendingString:@"webinarWithID.json"];
    NSString *phpString = [[[NSUserDefaults standardUserDefaults] stringForKey:@"serverPath"]  stringByAppendingString:@"webinarIDCreator.php"];
    NSString *phpSecondString = [[[NSUserDefaults standardUserDefaults] stringForKey:@"serverPath"]  stringByAppendingString:@"webinarCreator.php"];
    NSString *entityName = @"Webinar";
    
    [self runScript:phpString ];
    [self runScript:phpSecondString];
    [self initDataDownloadForURLString:jsonString forEntityName:entityName checkVersion:NO];
}

-(void)runVeranstaltungScripts{
    NSString *jsonString = [[[NSUserDefaults standardUserDefaults] stringForKey:@"serverPath"]  stringByAppendingString:@"event.json"];
    NSString *phpString = [[[NSUserDefaults standardUserDefaults] stringForKey:@"serverPath"]  stringByAppendingString:@"eventCreator.php"];
    NSString *entityName = @"Veranstaltung";
    
    [self runScript:phpString ];
    [self initDataDownloadForURLString:jsonString forEntityName:entityName checkVersion:NO];
}

-(void)runSchulungScriptsWithWait{
    NSString *jsonString = [[[NSUserDefaults standardUserDefaults] stringForKey:@"serverPath"] stringByAppendingString:@"audits.json"];
    NSString *entityName = @"Schulung";
    
    [self initDataDownloadForURLString:jsonString forEntityName:entityName checkVersion:YES];
}

-(void)runSchulungsterminScriptsWithWait{
    NSString *jsonString = [[[NSUserDefaults standardUserDefaults] stringForKey:@"serverPath"]  stringByAppendingString:@"allAudits.json"];
    NSString *phpString = [[[NSUserDefaults standardUserDefaults] stringForKey:@"serverPath"]  stringByAppendingString:@"allAuditionsCreator.php"];
    NSString *entityName = @"Schulungstermin";
    
    [self runScript:phpString WaitUntilFileIsCreated:jsonString];
    [self initDataDownloadForURLString:jsonString forEntityName:entityName checkVersion:NO];
}

-(void)runWebinarScriptsWithWait{
    NSString *jsonString = [[[NSUserDefaults standardUserDefaults] stringForKey:@"serverPath"]  stringByAppendingString:@"webinarWithID.json"];
    NSString *phpString = [[[NSUserDefaults standardUserDefaults] stringForKey:@"serverPath"]  stringByAppendingString:@"webinarIDCreator.php"];
    NSString *phpSecondString = [[[NSUserDefaults standardUserDefaults] stringForKey:@"serverPath"]  stringByAppendingString:@"webinarCreator.php"];
    NSString *entityName = @"Webinar";
    
    [self runScript:phpSecondString];
    [self runScript:phpString WaitUntilFileIsCreated:jsonString];
    [self initDataDownloadForURLString:jsonString forEntityName:entityName checkVersion:NO];
}

-(void)runVeranstaltungScriptsWithWait{
    NSString *jsonString = [[[NSUserDefaults standardUserDefaults] stringForKey:@"serverPath"]  stringByAppendingString:@"event.json"];
    NSString *phpString = [[[NSUserDefaults standardUserDefaults] stringForKey:@"serverPath"]  stringByAppendingString:@"eventCreator.php"];
    NSString *entityName = @"Veranstaltung";
    
    [self runScript:phpString WaitUntilFileIsCreated:jsonString];
    [self initDataDownloadForURLString:jsonString forEntityName:entityName checkVersion:NO];
}

-(NSURLConnection*)runScript:(NSString*)script{
    NSURL *updateAuditionsURL = [NSURL URLWithString:[script stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    NSURLRequest *request = [[NSURLRequest alloc]initWithURL:updateAuditionsURL];
    NSURLConnection *theConnection = [[NSURLConnection alloc]initWithRequest:request delegate:self];
    return theConnection;
}

-(NSURLConnection*)runScript:(NSString*)script WaitUntilFileIsCreated:(NSString*)fileURL{
    int trys = 0;
    NSDate *currentDate = [NSDate date];
    NSURL *updateAuditionsURL = [NSURL URLWithString:[script stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    NSURLRequest *scriptRequest = [[NSURLRequest alloc]initWithURL:updateAuditionsURL];
    NSURLConnection *theConnection = [[NSURLConnection alloc]initWithRequest:scriptRequest delegate:self];
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    BOOL waitFlag = true;
    // create a HTTP request to get the file information from the web server
    NSURL* url = [NSURL URLWithString:fileURL];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"HEAD"];
    while(waitFlag && trys<=300){
        NSHTTPURLResponse* response;
        [NSURLConnection sendSynchronousRequest:request
                              returningResponse:&response error:nil];
        
        // get the last modified info from the HTTP header
        NSString* httpLastModified = nil;
        if ([response respondsToSelector:@selector(allHeaderFields)])
        {
            httpLastModified = [[response allHeaderFields]
                                objectForKey:@"Last-Modified"];
        }
        
        // setup a date formatter to query the server file's modified date
       
        df.dateFormat = @"EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'";
        df.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        df.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        
        
        NSDate *serverFileDate = [df dateFromString:httpLastModified];
        serverFileDate = [serverFileDate dateByAddingTimeInterval:60*60]; //add hour to make time right
        NSLog(@"serverfile: %@, currentDate: %@",serverFileDate,currentDate);
        if(serverFileDate==nil){
            NSLog(@"Couldn't get the version-date for the database-file from server!");
            waitFlag=false;
        }
        if([[currentDate laterDate:serverFileDate]isEqualToDate:serverFileDate]){
            waitFlag=false;
        }
        trys++;
    }
    if(trys==300){
        NSLog(@"Operation timed out!");
        return nil;
    }
    return theConnection;
}

-(void)initDataDownloadForURLString:(NSString*)inURL forEntityName:(NSString*)entityName checkVersion:(BOOL)check{
    if(check){
        BOOL updateJson = [self checkForNewFileVersionOnServerByURL:inURL withEntityName:entityName];
        if(updateJson){
            [self fillInDataByURLString:inURL forEntityName:entityName];
            [self setSyncFlag];
        }
    }
    else{
        [self clearDataForUpdatewithEntityName:entityName];
        [self fillInDataByURLString:inURL forEntityName:entityName];
        [self setSyncFlag];
    }
    NSError *theError;
    [self.managedObjectContext save:&theError];
    if(theError != nil){
        NSLog(@"Failed to save Data; %@",theError);
    }
}

-(BOOL)checkForNewFileVersionOnServerByURL:(NSString*)inURL withEntityName:(NSString*)name{
    
    // create a HTTP request to get the file information from the web server
    NSURL* url = [NSURL URLWithString:inURL];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"HEAD"];
    
    NSHTTPURLResponse* response;
    [NSURLConnection sendSynchronousRequest:request
                          returningResponse:&response error:nil];
    
    // get the last modified info from the HTTP header
    NSString* httpLastModified = nil;
    if ([response respondsToSelector:@selector(allHeaderFields)])
    {
        httpLastModified = [[response allHeaderFields]
                            objectForKey:@"Last-Modified"];
    }
    
    // setup a date formatter to query the server file's modified date
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'";
    df.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    df.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    
    NSDate *serverFileDate = [df dateFromString:httpLastModified];
    if(serverFileDate==nil){
        NSLog(@"Couldn't get the version-date for the database-file from server!");
        return NO;
    }
    
    NSDate *syncDate = (NSDate*)[[NSUserDefaults standardUserDefaults]objectForKey:@"syncDate"];
    
    if([syncDate compare:serverFileDate]==NSOrderedAscending){
        NSLog(@"Found a new version (%@) after last sync on: %@",serverFileDate,syncDate);
        [self clearDataForUpdatewithEntityName:name];
        return YES;
    }
    if(syncDate==nil){
        NSLog(@"Initial CoreData Import");
        return YES;
    }
    NSLog(@"Snyced DataBase on %@ is up to Date with ServerFile: %@",syncDate,serverFileDate);
    return NO;
}

-(void)clearDataForUpdatewithEntityName:(NSString*)name{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:name inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        NSLog(@"Could not delete Entity Objects");
    }
    
    for (NSManagedObject *currentObject in fetchedObjects) {
        [self.managedObjectContext deleteObject:currentObject];
    }
    
    [self saveContext];

}

-(void)fillInDataByURLString:(NSString*)inURL forEntityName:(NSString*)inEntityName{
    NSError *theError;
    NSURL *theUrl = [NSURL URLWithString:inURL];
    NSData *theData = [NSData dataWithContentsOfURL:theUrl options:0 error:&theError];
    
    NSArray *jsonObject = [NSJSONSerialization JSONObjectWithData:theData options:0 error:&theError];
    
    if(!jsonObject){
        NSLog(@"There was a Problem retriving the Json File: %@", theError);
    }
    else{
        for(NSDictionary *dict in jsonObject){
            [self createObjectFromDictionary:dict forEntityName:inEntityName];
        }
        [self saveContext];
    }
    
}

-(void)setSyncFlag{
    NSDate* sourceDate = [NSDate date];
    
    NSTimeZone* sourceTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    NSTimeZone* destinationTimeZone = [NSTimeZone systemTimeZone];
    
    NSInteger sourceGMTOffset = [sourceTimeZone secondsFromGMTForDate:sourceDate];
    NSInteger destinationGMTOffset = [destinationTimeZone secondsFromGMTForDate:sourceDate];
    NSTimeInterval interval = destinationGMTOffset - sourceGMTOffset;
    
    NSDate* destinationDate = [[NSDate alloc] initWithTimeInterval:interval sinceDate:sourceDate];
    
    [[NSUserDefaults standardUserDefaults] setObject:destinationDate forKey:@"syncDate"];
    [[NSUserDefaults standardUserDefaults]synchronize];
}

-(void)createObjectFromDictionary:(NSDictionary *)inDictionary forEntityName:(NSString*)inEntityName{
    NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:inEntityName inManagedObjectContext:self.managedObjectContext];
    
    NSDictionary *attributes = [[NSEntityDescription entityForName:inEntityName inManagedObjectContext:self.managedObjectContext] attributesByName];
    
    for(NSString *attr in attributes){
        [object setValue:[inDictionary valueForKey:attr] forKey:attr];
    }
    NSLog(@"Successfully updated CoreData: %@",object);
}


-(NSManagedObjectModel *)managedObjectModel{
    if(_managedObjectModel == nil){
        NSURL *theURL = [[NSBundle mainBundle]URLForResource:@"Model" withExtension:@"momd"];
        _managedObjectModel = [[NSManagedObjectModel alloc]initWithContentsOfURL:theURL];
    }
    return _managedObjectModel;
}

-(NSURL *)persistentStoreURL{
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Data.sql"];
    
    return storeURL;
}

- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

-(NSPersistentStoreCoordinator *)persistentStoreCoordinator{
    if(_persistentStoreCoordinator == nil) {
        NSURL *theURL = self.persistentStoreURL;
        NSError *theError = nil;
        NSPersistentStoreCoordinator *theCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
        
        if([theCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:theURL options:nil error:&theError]) {
            self.persistentStoreCoordinator = theCoordinator;
        }
        else {
            NSLog(@"Error: %@", theError);
        }
    }
    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext {
    if (_managedObjectContext == nil) {
        NSPersistentStoreCoordinator *theCoordinator = self.persistentStoreCoordinator;
        
        if(theCoordinator != nil) {
            _managedObjectContext = [[NSManagedObjectContext alloc] init];
            _managedObjectContext.persistentStoreCoordinator = theCoordinator;
        }
    }
    return _managedObjectContext;
}

- (void)saveContext{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            
            NSLog(@"Saving didn't work so well.. Error: %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark AppDelegates
- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [self saveContext];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
