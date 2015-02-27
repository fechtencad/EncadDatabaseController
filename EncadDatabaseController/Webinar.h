//
//  Webinar.h
//  EncadDatabaseController
//
//  Created by Bernd Fecht (encad-consulting.de) on 27.02.15.
//  Copyright (c) 2015 Bernd Fecht (encad-consulting.de). All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Webinar : NSManagedObject

@property (nonatomic, retain) NSString * datum;
@property (nonatomic, retain) NSString * end_zeit;
@property (nonatomic, retain) NSString * link;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * start_zeit;
@property (nonatomic, retain) NSString * id;

@end
