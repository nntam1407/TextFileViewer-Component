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

/*============================================================================
 PROTOCOL
 =============================================================================*/

/*============================================================================
 Interface:   TextDocument
 =============================================================================*/


@interface TextDocument : NSObject

@property (readonly, nonatomic) NSString *filePath;
@property (assign, nonatomic) NSUInteger blockSize; // Unit is byte. Default is kBufferSize

@property (readonly, nonatomic) BOOL fileNotFound;
@property (readonly, nonatomic) NSUInteger fileSize; // bytes
@property (readonly, nonatomic) NSUInteger blockNumbers;

- (instancetype)initWithFilePath:(NSString *)filePath;
- (NSString *)readTextAtBlockIndex:(NSUInteger)blockIndex;

@end
