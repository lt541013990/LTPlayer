//
//  ViewController.m
//  LTPlayer
//
//  Created by lt on 2017/12/25.
//  Copyright © 2017年 lt. All rights reserved.
//

#import "ViewController.h"
#import "LTPlayerView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    LTPlayerView *view = [[LTPlayerView alloc] initWithFrame:CGRectMake(0, 64, [UIScreen mainScreen].bounds.size.width, 200)];
    [self.view addSubview:view];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
