//
//  ViewController.m
//  TextViewer
//
//  Created by Tam Nguyen on 4/16/15.
//  Copyright (c) 2015 Tam Nguyen. All rights reserved.
//

#import "ViewController.h"
#import "TextDocument.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"log" ofType:@"txt"];
    TextDocument *document = [[TextDocument alloc] initWithFilePath:filePath];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
