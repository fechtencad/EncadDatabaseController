//
//  WebinarCreator.h
//  EncadDatabaseController
//
//  Created by Bernd Fecht (encad-consulting.de) on 20.02.15.
//  Copyright (c) 2015 Bernd Fecht (encad-consulting.de). All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Webinars.h"
#import "Webinar.h"

@interface WebinarCreator : UIViewController

@property (nonatomic,strong) Webinars *webinarController;

@property (nonatomic, strong) Webinar *webinar;

@end
