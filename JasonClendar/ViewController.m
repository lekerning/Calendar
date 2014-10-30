//
//  ViewController.m
//  JasonClendar
//
//  Created by Jason.zhang on 10/30/14.
//  Copyright (c) 2014 Jason.zhang. All rights reserved.
//

#import "ViewController.h"
#import "VRGCalendarView.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    
    VRGCalendarView *calendar = [[VRGCalendarView alloc] init];
    CGRect cR = calendar.frame;
    cR.origin.x = 30;
    cR.origin.y = 50;
    calendar.frame = cR;
    [self.view addSubview:calendar];
    

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
