//
//  Webinar.h
//  EncadDatabaseController
//
//  Created by Bernd Fecht (encad-consulting.de) on 15.01.15.
//  Copyright (c) 2015 Bernd Fecht (encad-consulting.de). All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Webinar : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * anfangs_datum;
@property (nonatomic, retain) NSString * end_datum;
@property (nonatomic, retain) NSString * uhrzeit;

@end
