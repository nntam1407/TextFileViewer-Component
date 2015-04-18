/*============================================================================
 PROJECT: TextViewer
 FILE:    TextSearchResult.h
 AUTHOR:  Tam Nguyen
 DATE:    4/18/15
 =============================================================================*/

/*============================================================================
 IMPORT
 =============================================================================*/
#import <Foundation/Foundation.h>

/*============================================================================
 MACRO
 =============================================================================*/

/*============================================================================
 PROTOCOL
 =============================================================================*/

/*============================================================================
 Interface:   TextSearchResult
 =============================================================================*/


@interface TextSearchResult : NSObject

// range of block data contain this word
@property (readonly, nonatomic) NSRange blockDataRange;

// Range of this keyword on text after comvert from bytes to NSString
@property (readonly, nonatomic) NSRange rangeInBlockText;

- (instancetype)initWithBlockDataRange:(NSRange)blockDataRange rangeOfKeywordInBlockText:(NSRange)rangeInBlockText;

@end
