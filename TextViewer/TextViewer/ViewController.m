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

#import <MobileCoreServices/MobileCoreServices.h> // For UTI

@interface ViewController () <UITextFieldDelegate, UIScrollViewDelegate, TextDocumentDelegates, UIDocumentInteractionControllerDelegate>

@property (strong, nonatomic) TextDocument *document;
@property (weak, nonatomic) IBOutlet TextFileView *textView;
@property (weak, nonatomic) IBOutlet UIButton *searchButton;
@property (weak, nonatomic) IBOutlet UILabel *searchResultCount;

@property (assign, nonatomic) NSInteger currentSearchIndex;

@property (strong, nonatomic) UIDocumentInteractionController *docController;

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
        
        // Refresh content
        [self.textView refreshContent];
    } else {
        self.currentSearchIndex = -1;
        [self.document startSeachWithText:@"java"];
    }
}

- (IBAction)didChangeFontSize:(UISlider *)sender {
    self.textView.font = [self.textView.font fontWithSize:sender.value];
}

- (IBAction)didTouchPreviousResult:(id)sender {
    self.currentSearchIndex--;
    
    if (self.currentSearchIndex >= 0 && self.document.searchResult.count > 0) {
        TextSearchResult *result = self.document.searchResult[self.currentSearchIndex];
        [self.textView gotoSearchResult:result animated:YES];
    }
}

- (IBAction)didTouchNextResult:(id)sender {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"xlsx"];
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    
    _docController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
    self.docController.delegate = self;
    self.docController.UTI = [self UTIForURL:fileURL];
    
    [self.docController presentOpenInMenuFromRect:CGRectZero inView:self.view animated:YES];
    
//    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[[NSURL fileURLWithPath:filePath]] applicationActivities:nil];
//    
////    NSArray *excludedActivities = @[UIActivityTypePostToTwitter, UIActivityTypePostToFacebook,
////                                    UIActivityTypePostToWeibo,
////                                    UIActivityTypeMessage, UIActivityTypeMail,
////                                    UIActivityTypeCopyToPasteboard,
////                                    UIActivityTypeAssignToContact,
////                                    UIActivityTypeAddToReadingList, UIActivityTypePostToFlickr,
////                                    UIActivityTypePostToVimeo, UIActivityTypePostToTencentWeibo];
////    activityViewController.excludedActivityTypes = excludedActivities;
//    
//    [self presentViewController:activityViewController animated:YES completion:^{
//        
//    }];
    
    self.currentSearchIndex++;
    
    if (self.currentSearchIndex < self.document.searchResult.count && self.document.searchResult.count > 0) {
        TextSearchResult *result = self.document.searchResult[self.currentSearchIndex];
        [self.textView gotoSearchResult:result animated:YES];
    }
}

#pragma mark - UIDocumentInteractionControllerDelegate

- (void) documentInteractionControllerWillPresentOpenInMenu:(UIDocumentInteractionController *)controller
{
    // Inform delegate
//    if([self.delegate respondsToSelector:@selector(openInAppActivityWillPresentDocumentInteractionController:)]) {
//        [self.delegate openInAppActivityWillPresentDocumentInteractionController:self];
//    }
}

- (void) documentInteractionControllerDidDismissOpenInMenu: (UIDocumentInteractionController *) controller
{
    // Inform delegate
//    if([self.delegate respondsToSelector:@selector(openInAppActivityDidDismissDocumentInteractionController:)]) {
//        [self.delegate openInAppActivityDidDismissDocumentInteractionController:self];
//    }
}

- (void) documentInteractionController:(UIDocumentInteractionController *)controller didEndSendingToApplication:(NSString *)application
{
    // Inform delegate
//    if([self.delegate respondsToSelector:@selector(openInAppActivityDidEndSendingToApplication:)]) {
//        [self.delegate openInAppActivityDidDismissDocumentInteractionController:self];
//    }
//    if ([self.delegate respondsToSelector:@selector(openInAppActivityDidSendToApplication:)]) {
//        [self.delegate openInAppActivityDidSendToApplication:application];
//    }
//    
//    // Inform app that the activity has finished
//    [self activityDidFinish:YES];
}

#pragma mark - Support methods

- (NSString *)UTIForURL:(NSURL *)url
{
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)url.pathExtension, NULL);
    return (NSString *)CFBridgingRelease(UTI) ;
}

#pragma mark - TextDocument's delegates

- (void)textDocument:(TextDocument *)document beginSearchText:(NSString *)keyword {
    self.searchButton.selected = YES;
}

- (void)textDocument:(TextDocument *)document didSearchInBlockIndex:(int)blockIndex keyword:(NSString *)keyword {
    // Should update result count
    NSUInteger count = [document.searchResult count];
    self.searchResultCount.text = [NSString stringWithFormat:count >= self.document.maxSearchResult ? @"Found %d+ items" : @"Found %d items", count];
    
    // Refresh content
    [self.textView refreshContentAtBlockIndex:blockIndex];
}

- (void)textDocument:(TextDocument *)document finishedSearchText:(NSString *)keyword {
    self.searchButton.enabled = YES;
}

@end
