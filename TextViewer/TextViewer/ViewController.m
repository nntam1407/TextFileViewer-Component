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

@interface ViewController () <UITextFieldDelegate, UIScrollViewDelegate, TextDocumentDelegates>

@property (strong, nonatomic) TextDocument *document;
@property (weak, nonatomic) IBOutlet TextFileView *textView;
@property (weak, nonatomic) IBOutlet UIButton *searchButton;
@property (weak, nonatomic) IBOutlet UILabel *searchResultCount;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"log" ofType:@"txt"];
    _document = [[TextDocument alloc] initWithFilePath:filePath];
    _document.blockSize = 2048;
    _document.delegate = self;
    
    [self.textView beginRenderDocument:self.document];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)didTouchStartSearch:(id)sender {
    if (self.searchButton.selected) {
        [self.document cancelSearch];
        self.searchButton.selected = NO;
    } else {
        [self.document startSeachWithText:@"java"];
    }
}

#pragma mark - TextDocument's delegates

- (void)textDocument:(TextDocument *)document beginSearchText:(NSString *)keyword {
    self.searchButton.selected = YES;
}

- (void)textDocument:(TextDocument *)document didSearchInBlocTextWithKeyword:(NSString *)keyword {
    // Should update result count
    NSUInteger count = [document.searchResult count];
    self.searchResultCount.text = [NSString stringWithFormat:@"Found %d items", count];
}

- (void)textDocument:(TextDocument *)document finishedSearchText:(NSString *)keyword {
    self.searchButton.enabled = YES;
}

@end
