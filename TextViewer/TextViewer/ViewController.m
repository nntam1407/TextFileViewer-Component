//
//  ViewController.m
//  TextViewer
//
//  Created by Tam Nguyen on 4/16/15.
//  Copyright (c) 2015 Tam Nguyen. All rights reserved.
//

#import "ViewController.h"
#import "TextDocument.h"
#import "TextFileView.h"
#import "TextFileScrollView.h"

@interface ViewController () <UITextFieldDelegate, UIScrollViewDelegate>

@property (strong, nonatomic) TextDocument *document;
@property (weak, nonatomic) IBOutlet TextFileView *textFileView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"log" ofType:@"txt"];
    _document = [[TextDocument alloc] initWithFilePath:filePath];
    [self.textFileView beginRenderDocument:self.document];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
