//
//  EncadAkademie.m
//  EncadDatabaseController
//
//  Created by Bernd Fecht (encad-consulting.de) on 19.01.15.
//  Copyright (c) 2015 Bernd Fecht (encad-consulting.de). All rights reserved.
//

#import "EncadAkademie.h"

@interface EncadAkademie ()
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *refresh;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *back;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *foreward;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *stop;

@end

@implementation EncadAkademie

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.title=@"encad-akademie.de";
    
    //UIWebView settings
    NSURL *url = [NSURL URLWithString:@"http://www.encad-akademie.de"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
    
    //Activity Indicator settings
    self.activityIndicator.hidesWhenStopped=YES;
    self.activityIndicator.color = [UIColor purpleColor];
    [self.activityIndicator startAnimating];
    
    [NSTimer scheduledTimerWithTimeInterval:0.5
                                             target:self
                                           selector:@selector(loading)
                                           userInfo:nil
                                            repeats:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
}

-(void)loading{
    if (!_webView.loading)
        [self.activityIndicator stopAnimating];
    else
        [self.activityIndicator startAnimating];
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
