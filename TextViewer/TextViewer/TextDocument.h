/*============================================================================
 PROJECT: TextViewer
 FILE:    TextDocument.h
 AUTHOR:  Tam Nguyen
 DATE:    4/16/15
 =============================================================================*/

/*============================================================================
 IMPORT
 =============================================================================*/
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/*============================================================================
 MACRO
 =============================================================================*/

@class TextDocument;
@class TextSearchResult;
/*============================================================================
 PROTOCOL
 =============================================================================*/

@protocol TextDocumentDelegates <NSObject>

@optional

- (void)textDocument:(TextDocument *)document beginSearchText:(NSString *)keyword;
- (void)textDocument:(TextDocument *)document searchText:(NSString *)keyword didFoundResult:(TextSearchResult *)result;
- (void)textDocument:(TextDocument *)document didSearchInBlockIndex:(int)blockIndex keyword:(NSString *)keyword;
- (void)textDocument:(TextDocument *)document finishedSearchText:(NSString *)keyword;
- (void)textDocument:(TextDocument *)document searchText:(NSString *)keyword failedWithError:(NSError *)error;

@end

/*============================================================================
 Interface:   TextDocument
 =============================================================================*/


@interface TextDocument : NSObject {
    __weak id<TextDocumentDelegates> _delegate;
}

@property (weak, nonatomic) id<TextDocumentDelegates> delegate;

@property (readonly, nonatomic) NSString *filePath;
@property (assign, nonatomic) NSUInteger blockSize; // Unit is byte. Default is kBufferSize

@property (readonly, nonatomic) BOOL fileNotFound;
@property (readonly, nonatomic) NSUInteger fileSize; // bytes
@property (readonly, nonatomic) NSStringEncoding fileEncoding;
@property (readonly, nonatomic) NSUInteger blockNumbers;

/* Properties for search */
@property (readonly, nonatomic) BOOL isSearching;
@property (assign, nonatomic) NSUInteger maxSearchResult;
@property (readonly, nonatomic) NSMutableArray *searchResult;

- (instancetype)initWithFilePath:(NSString *)filePath;

#pragma mark - Read text methods

- (NSAttributedString *)readTextAtBlockIndex:(NSUInteger)blockIndex hightlightSearch:(BOOL)hightlightSearch;
- (NSAttributedString *)readTextInRange:(NSRange)range;

#pragma mark - Supoort for search

- (void)startSeachWithText:(NSString *)text;
- (void)cancelSearch;

@end
