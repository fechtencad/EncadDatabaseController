//
//  EventCreator.h
//  EncadDatabaseController
//
//  Created by Bernd Fecht (encad-consulting.de) on 15.01.15.
//  Copyright (c) 2015 Bernd Fecht (encad-consulting.de). All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Events.h"
#import "Veranstaltung.h"

@interface EventCreator : UIViewController<UITextFieldDelegate>

@property (nonatomic, strong) Events *eventController;

@property (nonatomic,strong) Veranstaltung *event;

@end
