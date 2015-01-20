//
//  AppDelegate.h
//  EncadDatabaseController
//
//  Created by Bernd Fecht (encad-consulting.de) on 08.01.15.
//  Copyright (c) 2015 Bernd Fecht (encad-consulting.de). All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;


-(void)runScriptOperations;

-(void)runSchulungScripts;

-(void)runSchulungsterminScripts;

-(void)runWebinarScripts;

-(void)runVeranstaltungScripts;

@end

